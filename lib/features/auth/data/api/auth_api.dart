// Capa de comunicación HTTP para autenticación.
//
// Implementa las llamadas a los endpoints de auth del backend:
// - POST /api/v1/auth/login
// - POST /api/v1/auth/register
// - POST /api/v1/auth/refresh
//
// Recibe una instancia de Dio inyectada (sin crearla internamente)
// para permitir tests con mocks y compartir la configuración
// de ApiClient (base URL, timeouts, interceptors).

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';

/// Cliente HTTP para los endpoints de autenticación.
///
/// Cada método retorna [AuthResponse] o lanza [ApiException]
/// (o subtipo) en caso de error.
///
/// Los errores HTTP se convierten con [ApiException.fromStatusCode]:
/// - 401/403 → [AuthException]
/// - 5xx → [ServerException]
/// - 0 (red) → [NetworkException]
class AuthApi {
  final Dio _dio;

  /// Crea un [AuthApi] con la instancia de [Dio] inyectada.
  ///
  /// [dio] debe estar configurado con la base URL y headers
  /// base (Content-Type, Accept) — ver ApiClient.create().
  const AuthApi({required Dio dio}) : _dio = dio;

  /// Autentica al usuario con [email] y [password].
  ///
  /// Endpoint: `POST /api/v1/auth/login`
  /// Body: `{ "email": ..., "password": ... }`
  Future<AuthResponse> login(
    String email,
    String password, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
        cancelToken: cancelToken,
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Registra un nuevo usuario con [email] y [password].
  ///
  /// Endpoint: `POST /api/v1/auth/register`
  /// Body: `{ "email": ..., "password": ... }`
  Future<AuthResponse> register(
    String email,
    String password, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/register',
        data: {'email': email, 'password': password},
        cancelToken: cancelToken,
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Renueva los tokens usando [refreshToken].
  ///
  /// Endpoint: `POST /api/v1/auth/refresh`
  /// Body: `{ "refreshToken": ... }`
  Future<AuthResponse> refresh(
    String refreshToken, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
        cancelToken: cancelToken,
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
