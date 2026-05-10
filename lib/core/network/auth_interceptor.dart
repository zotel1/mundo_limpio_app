// Interceptor de autenticación para Dio.
//
// Maneja el ciclo completo de JWT:
// - onRequest: agrega el token al header Authorization
// - onError: intercepta 401, intenta refresh, retry
//
// Usa QueuedInterceptor (no Interceptor) porque necesitamos
// que los requests se encolen automáticamente mientras el
// refresh está en progreso (R4.3 — dedup de concurrentes).

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Interceptor que maneja autenticación JWT automática.
///
/// Inyecta el access token en cada request saliente (onRequest).
/// Si recibe un 401, intenta refrescar el token silenciosamente
/// (onError). Si el refresh es exitoso, retry la request original.
/// Si falla, limpia los tokens y propaga el error.
///
/// [dio]: instancia de Dio para retry de requests originales.
/// [tokenDio]: instancia SEPARADA de Dio para llamadas de refresh
///   (no debe tener este interceptor para evitar loops infinitos).
/// [tokenStorage]: wrapper de flutter_secure_storage.
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final Dio tokenDio;
  final TokenStorage tokenStorage;

  AuthInterceptor({
    required this.dio,
    required this.tokenDio,
    required this.tokenStorage,
  });

  /// Flag que indica si hay un refresh en progreso.
  /// Se usa para deduplicar refreshes concurrentes (R4.3).
  bool _isRefreshing = false;

  /// Cola de requests que esperan mientras se refresca el token.
  /// Cada entrada tiene: options (request original), handler, error original.
  final _pendingRequests = <({
    RequestOptions options,
    ErrorInterceptorHandler handler,
    DioException error
  })>[];

  /// Wrapper seguro para [ErrorInterceptorHandler.next].
  ///
  /// Dio usa [Completer.completeError] internamente para comunicar
  /// estado entre interceptors. El error [InterceptorState] se propaga
  /// como excepción no manejada si nadie lo captura. Lo envolvemos
  /// en un Future con .catchError() para aislarlo.
  void _safeNext(DioException err, ErrorInterceptorHandler handler) {
    Future.microtask(() => handler.next(err)).catchError((_) {});
  }

  /// Wrapper seguro para [ErrorInterceptorHandler.reject].
  void _safeReject(DioException err, ErrorInterceptorHandler handler) {
    Future.microtask(() => handler.reject(err)).catchError((_) {});
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // No modificar requests de auth (login, register, refresh)
    // que no requieren token
    if (options.path.contains('/auth/')) {
      handler.next(options);
      return;
    }

    // Agregar token si existe (R1.1)
    try {
      final tokens = await tokenStorage.readTokens();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.access}';
      }
    } catch (_) {
      // Si falla la lectura del storage, dejamos la request sin token
      // El backend devolverá 401 y el onError lo manejará
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // No interceptar errores del propio endpoint de refresh
    // (esto evitaría loops infinitos de refresh)
    if (err.requestOptions.path.contains('/auth/refresh')) {
      _safeNext(err, handler);
      return;
    }

    // Solo interceptar 401 (no autorizado)
    if (err.response?.statusCode != 401) {
      _safeNext(err, handler);
      return;
    }

    // Si ya hay un refresh en progreso, encolar este request
    // y retry después (R4.3 — dedup de concurrentes)
    if (_isRefreshing) {
      _pendingRequests.add((
        options: err.requestOptions,
        handler: handler,
        error: err,
      ));
      return;
    }

    // Iniciar refresh
    _isRefreshing = true;

    try {
      // Leer el refresh token del storage
      final tokens = await tokenStorage.readTokens();
      if (tokens == null) {
        // No hay refresh token para renovar → error de autenticación
        _isRefreshing = false;
        _safeNext(err, handler);
        return;
      }

      // Llamar al endpoint de refresh (R4.1)
      final refreshResponse = await tokenDio.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': tokens.refresh},
      );

      final newAccess = refreshResponse.data['accessToken'] as String;
      final newRefresh = refreshResponse.data['refreshToken'] as String;

      // Guardar los nuevos tokens
      await tokenStorage.saveTokens(newAccess, newRefresh);

      // Retry la request original con el nuevo access token (R4.1)
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await dio.fetch(err.requestOptions);
      // Resolver sincrónicamente (sin Future.microtask) para que el error
      // queue del QueuedInterceptor procese los siguientes errores MIENTRAS
      // _isRefreshing sigue true. Así los requests concurrentes (R4.3) se
      // encolan en _pendingRequests en vez de disparar un segundo refresh.
      handler.resolve(retryResponse);

      // Bucle: procesa TODOS los requests encolados, incluyendo los que
      // se agregan durante el procesamiento (R4.3 — drenado del error queue).
      // Por cada pending que resolvemos sincrónicamente, el error queue
      // puede encolar más en _pendingRequests.
      while (_pendingRequests.isNotEmpty) {
        final pending = _pendingRequests.removeAt(0);
        try {
          pending.options.headers['Authorization'] = 'Bearer $newAccess';
          final response = await dio.fetch(pending.options);
          pending.handler.resolve(response); // Sincrónico — drena error queue
        } catch (e) {
          _safeReject(
            e is DioException ? e : _toDioException(e, pending.options),
            pending.handler,
          );
        }
      }
      _isRefreshing = false;
    } catch (e) {
      // El refresh falló — limpiar tokens y propagar error (R4.2)
      await tokenStorage.clear();
      _isRefreshing = false;
      _pendingRequests.clear();
      _safeNext(err, handler);
    }
  }

  /// Convierte cualquier error a [DioException] para los handlers encolados.
  DioException _toDioException(Object error, RequestOptions options) {
    if (error is DioException) return error;
    return DioException(
      requestOptions: options,
      error: error,
      type: DioExceptionType.unknown,
    );
  }
}
