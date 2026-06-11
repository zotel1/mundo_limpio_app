// Contrato abstracto del repositorio de autenticación.
//
// Define la interfaz que la capa de presentación (Provider)
// usa para autenticación, sin depender de implementaciones
// concretas de red o almacenamiento.
//
// Domain layer: NO importa Flutter, Dio, ni flutter_secure_storage.
// Solo tipos de Dart puro y modelos del dominio.

import 'package:dio/dio.dart';

import '../entities/auth_session.dart';

/// Repositorio de autenticación.
///
/// Métodos:
/// - [login]: autentica con email+password, retorna sesión
/// - [register]: registra nuevo usuario, retorna sesión
/// - [logout]: limpia la sesión local
/// - [refreshToken]: renueva tokens usando el refresh token
/// - [isLoggedIn]: verifica si hay una sesión activa
abstract class AuthRepository {
  /// Autentica al usuario con [email] y [password].
  ///
  /// Retorna [AuthSession] con los datos de la sesión si las credenciales
  /// son válidas. Lanza [ApiException] en caso de error.
  Future<AuthSession> login(
    String email,
    String password, {
    CancelToken? cancelToken,
  });

  /// Registra un nuevo usuario con [email] y [password].
  ///
  /// Retorna [AuthSession] si el registro es exitoso.
  /// Lanza [ApiException] si el email ya está registrado (409).
  Future<AuthSession> register(
    String email,
    String password, {
    CancelToken? cancelToken,
  });

  /// Cierra la sesión: elimina tokens locales.
  ///
  /// No invalida el refresh token en el backend (logout
  /// del lado del servidor se implementa si es necesario).
  Future<void> logout();

  /// Renueva los tokens usando [refreshToken].
  ///
  /// Retorna un nuevo [AuthSession] con access y refresh
  /// tokens actualizados. Lanza [AuthException] si el
  /// refresh token expiró.
  Future<AuthSession> refreshToken(
    String refreshToken, {
    CancelToken? cancelToken,
  });

  /// Verifica si hay una sesión activa localmente.
  ///
  /// Retorna `true` si existen tokens locales válidos.
  /// NO verifica si los tokens están expirados — eso
  /// se maneja automáticamente en AuthInterceptor.
  Future<bool> isLoggedIn();
}
