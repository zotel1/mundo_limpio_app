// Pruebas unitarias para AuthInterceptor.
// Testea a través de una instancia real de Dio con MockAdapter
// en vez de llamar al interceptor directamente, porque
// ErrorInterceptorHandler.next() usa completeError() internamente
// y la excepción se propaga al zone del test.
//
// TDD: RED — test escrito antes que la implementación
// R4 (onError): Usamos adapters HTTP mock + interceptores auxiliares
// para simular respuestas 401 sin depender de un backend real.

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/core/network/auth_interceptor.dart';
import 'package:mundo_limpio_app/core/storage/token_storage.dart';

class MockDio extends Mock implements Dio {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockRequestOptions extends Fake implements RequestOptions {}

// ---------------------------------------------------------------------------
// Adaptadores HTTP para simular respuestas del backend en tests R4
// ---------------------------------------------------------------------------

/// Adaptador que siempre retorna HTTP 200 para las llamadas de retry.
///
/// Se usa en el Dio interno del AuthInterceptor (el que hace los retry).
/// Así los retries nunca fallan por problemas del adapter.
class Always200Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"message":"success"}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adaptador para el tokenDio — simula el endpoint de refresh.
///
/// - [failRefresh]: si es true, retorna 401 (refresh fallido, R4.2)
/// - refreshCallCount: cuenta cuántas veces se llamó al refresh
class TokenTestAdapter implements HttpClientAdapter {
  int refreshCallCount = 0;
  bool failRefresh;

  TokenTestAdapter({this.failRefresh = false});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    refreshCallCount++;

    if (failRefresh) {
      return ResponseBody.fromString(
        '{"error":"Unauthorized"}',
        401,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      '{"accessToken":"new-access","refreshToken":"new-refresh"}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Interceptor que rechaza requests con 401 hasta N veces.
///
/// Se agrega DESPUÉS del AuthInterceptor en la cadena. Las requests
/// pasan por AuthInterceptor.onRequest (que agrega el token), luego
/// este interceptor las rechaza con 401 para simular un token expirado.
///
/// [max401Count]: cantidad de requests que reciben 401.
///   - R4.1/R4.2: 1 (solo la request original falla, el retry pasa)
///   - R4.3: 2 (dos requests originales fallan, ambos retries pasan)
class Test401OnRequestInterceptor extends Interceptor {
  int _rejectCount = 0;
  final int max401Count;

  Test401OnRequestInterceptor({this.max401Count = 1});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_rejectCount < max401Count) {
      _rejectCount++;
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
        true,
      ); // callFollowingErrorInterceptor=true: necesario para que Dio 5.x propague el error a onError
    } else {
      // Si ya pasamos el límite de 401, dejamos pasar la request
      handler.next(options);
    }
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockRequestOptions());
  });

  late Dio dio;
  late Dio tokenDio;
  late MockTokenStorage mockTokenStorage;
  late AuthInterceptor interceptor;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.com/api/v1'));
    tokenDio = Dio(BaseOptions(baseUrl: 'http://test.com/api/v1'));
    mockTokenStorage = MockTokenStorage();

    when(() => mockTokenStorage.readTokens()).thenAnswer((_) async => null);
    when(
      () => mockTokenStorage.saveTokens(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockTokenStorage.clear()).thenAnswer((_) async {});

    interceptor = AuthInterceptor(
      dio: dio,
      tokenDio: tokenDio,
      tokenStorage: mockTokenStorage,
    );
  });

  group('onRequest', () {
    test('should add Authorization header when tokens exist', () async {
      when(
        () => mockTokenStorage.readTokens(),
      ).thenAnswer((_) async => (access: 'access-123', refresh: 'refresh-456'));

      // AuthInterceptor debe ir PRIMERO en la cadena para que
      // modifique los options ANTES de que el wrappers los capture.
      RequestOptions? capturedOptions;
      dio.options.headers.clear();
      dio.interceptors.clear();
      dio.interceptors.add(interceptor);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          },
        ),
      );

      try {
        await dio.get('/test');
      } catch (_) {}

      // Verificar que el interceptor agregó el header antes del nuestro
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.headers['Authorization'], 'Bearer access-123');
    });

    test('should NOT add Authorization header when no tokens', () async {
      RequestOptions? capturedOptions;
      dio.interceptors.clear();
      dio.interceptors.add(interceptor);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          },
        ),
      );

      try {
        await dio.get('/test');
      } catch (_) {}

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.headers.containsKey('Authorization'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // R4 — onError: Auto-refresh de tokens (R4.1, R4.2, R4.3)
  // ---------------------------------------------------------------------------
  //
  // Estrategia de测试:
  // AuthInterceptor necesita TRES instancias de Dio:
  //   1. mainDio: la que usa la app (tiene AuthInterceptor + 401Simulator)
  //   2. retryDio: la que usa AuthInterceptor internamente para retry
  //      (tiene Always200Adapter para que el retry siempre funcione)
  //   3. tokenDio: la que usa AuthInterceptor para llamar al refresh
  //
  // El 401Simulator rechaza requests en onRequest con 401 ANTES de que
  // lleguen al adapter. Así forzamos a AuthInterceptor.onError a manejar
  // el error sin depender de un adapter HTTP real.
  //
  // Los retries (dio.fetch dentro del interceptor) van al retryDio que
  // tiene Always200Adapter → nunca fallan.
  //
  // El refresh va al tokenDio que tiene TokenTestAdapter.

  group('onError — R4: Auto-refresh de tokens', () {
    late AuthInterceptor r4Interceptor;
    late Dio mainDio;
    late Dio retryDio;
    late Dio r4TokenDio;
    late MockTokenStorage r4Storage;
    late TokenTestAdapter tokenAdapter;

    setUp(() {
      r4Storage = MockTokenStorage();

      // Mock: storage devuelve tokens existentes para que el
      // interceptor pueda leer el refresh token
      when(() => r4Storage.readTokens()).thenAnswer(
        (_) async => (access: 'test-access', refresh: 'test-refresh'),
      );
      when(() => r4Storage.saveTokens(any(), any())).thenAnswer((_) async {});
      when(() => r4Storage.clear()).thenAnswer((_) async {});

      // TokenDio con adapter que controla refresh
      r4TokenDio = Dio(BaseOptions(baseUrl: 'http://test.com/api/v1'));
      tokenAdapter = TokenTestAdapter();
      r4TokenDio.httpClientAdapter = tokenAdapter;

      // RetryDio — siempre retorna 200 para que los retries funcionen
      retryDio = Dio(BaseOptions(baseUrl: 'http://test.com/api/v1'));
      retryDio.httpClientAdapter = Always200Adapter();

      // Interceptor bajo prueba — apunta a retryDio para los retries
      r4Interceptor = AuthInterceptor(
        dio: retryDio,
        tokenDio: r4TokenDio,
        tokenStorage: r4Storage,
      );

      // MainDio — la que usa la app, tiene el AuthInterceptor + 401Simulator
      mainDio = Dio(BaseOptions(baseUrl: 'http://test.com/api/v1'));
      mainDio.interceptors.add(r4Interceptor);
    });

    // ===============================================================
    // R4.1: Refresh exitoso
    //   DADO un access token expirado pero refresh token válido
    //   CUANDO una request autenticada retorna 401
    //   THEN AuthInterceptor llama al refresh, retry la request original,
    //        y el usuario sigue en la pantalla actual
    // ===============================================================
    test('R4.1: 401 → refresh exitoso → retry original request', () async {
      // Arrange: refresh exitoso (no fail)
      tokenAdapter.failRefresh = false;
      mainDio.interceptors.add(Test401OnRequestInterceptor(max401Count: 1));

      // Act: llamada que retorna 401 inicialmente
      await mainDio.get('/api/v1/protected');

      // Assert: refresh fue llamado exactamente UNA vez
      expect(tokenAdapter.refreshCallCount, equals(1));

      // Assert: los nuevos tokens se guardaron en storage
      verify(() => r4Storage.saveTokens('new-access', 'new-refresh')).called(1);
    });

    // Triangulación: mismo escenario con un endpoint diferente
    test('R4.1: retry exitoso en endpoint distinto', () async {
      tokenAdapter.failRefresh = false;
      mainDio.interceptors.add(Test401OnRequestInterceptor(max401Count: 1));

      await mainDio.get('/api/v1/orders');

      expect(tokenAdapter.refreshCallCount, equals(1));
      verify(() => r4Storage.saveTokens('new-access', 'new-refresh')).called(1);
    });

    // ===============================================================
    // R4.2: Refresh fallido
    //   DADO access token Y refresh token expirados
    //   CUANDO una request autenticada retorna 401
    //   THEN AuthInterceptor intenta refresh, falla, limpia tokens,
    //        y propaga el error para que el router redirija a login
    // ===============================================================
    test(
      'R4.2: refresh falla con 401 → error propagado + tokens limpios',
      () async {
        // Arrange: refresh falla
        tokenAdapter.failRefresh = true;
        mainDio.interceptors.add(Test401OnRequestInterceptor(max401Count: 1));

        // Act & Assert: el error se propaga como DioException
        await expectLater(
          () => mainDio.get('/api/v1/protected'),
          throwsA(isA<DioException>()),
        );

        // Assert: refresh fue intentado una vez
        expect(tokenAdapter.refreshCallCount, equals(1));

        // Assert: storage.clear fue llamado (limpiar tokens expirados, R4.2)
        verify(() => r4Storage.clear()).called(1);
      },
    );

    // Triangulación: refresh fallido en endpoint diferente
    test('R4.2: refresh fallido en endpoint distinto propaga error', () async {
      tokenAdapter.failRefresh = true;
      mainDio.interceptors.add(Test401OnRequestInterceptor(max401Count: 1));

      await expectLater(
        () => mainDio.get('/api/v1/users'),
        throwsA(isA<DioException>()),
      );

      expect(tokenAdapter.refreshCallCount, equals(1));
      verify(() => r4Storage.clear()).called(1);
    });

    // ===============================================================
    // R4.3: Deduplicación de refreshes concurrentes
    //   DADO múltiples requests simultáneas con token expirado
    //   CUANDO el primer 401 gatilla un refresh
    //   THEN solo UNA llamada al refresh se hace y las requests
    //        encoladas se retryan con el nuevo token
    // ===============================================================
    test('R4.3: requests concurrentes → solo un refresh', () async {
      // Arrange: refresh exitoso, 2 requests reciben 401
      tokenAdapter.failRefresh = false;
      mainDio.interceptors.add(Test401OnRequestInterceptor(max401Count: 2));

      // Act: ambas requests se disparan concurrentemente
      await Future.wait([
        mainDio.get('/api/v1/protected/1'),
        mainDio.get('/api/v1/protected/2'),
      ]);

      // Assert: refresh fue llamado SOLO UNA vez (R4.3)
      expect(tokenAdapter.refreshCallCount, equals(1));

      // Assert: tokens guardados una sola vez
      verify(() => r4Storage.saveTokens('new-access', 'new-refresh')).called(1);
    });

    // Triangulación: 3 requests concurrentes, todas 401
    test('R4.3: tres requests concurrentes → solo un refresh', () async {
      tokenAdapter.failRefresh = false;
      mainDio.interceptors.add(Test401OnRequestInterceptor(max401Count: 3));

      await Future.wait([
        mainDio.get('/api/v1/a'),
        mainDio.get('/api/v1/b'),
        mainDio.get('/api/v1/c'),
      ]);

      expect(tokenAdapter.refreshCallCount, equals(1));
      verify(() => r4Storage.saveTokens('new-access', 'new-refresh')).called(1);
    });
  });
}
