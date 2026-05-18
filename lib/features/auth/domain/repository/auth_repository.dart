// Contrato abstracto del repositorio de autenticación.
//
// Define la interfaz que la capa de presentación (Provider)
// usa para autenticación, sin depender de implementaciones
// concretas de red o almacenamiento.
//
// Domain layer: NO importa Flutter, Dio, ni flutter_secure_storage.
// Solo tipos de Dart puro y modelos del dominio.

import '../../data/models/auth_response.dart';

/// Repositorio de autenticación.
///
/// Métodos:
/// - [login]: autentica con email+password, retorna tokens JWT
/// - [register]: registra nuevo usuario, retorna tokens JWT
/// - [logout]: limpia la sesión local
/// - [refreshToken]: renueva tokens usando el refresh token
/// - [isLoggedIn]: verifica si hay una sesión activa
abstract class AuthRepository {
  /// Autentica al usuario con [email] y [password].
  ///
  /// Retorna [AuthResponse] con los tokens JWT si las credenciales
  /// son válidas. Lanza [ApiException] en caso de error.
  Future<AuthResponse> login(String email, String password);

  /// Registra un nuevo usuario con [email] y [password].
  ///
  /// Retorna [AuthResponse] si el registro es exitoso.
  /// Lanza [ApiException] si el email ya está registrado (409).
  Future<AuthResponse> register(String email, String password);

  /// Cierra la sesión: elimina tokens locales.
  ///
  /// No invalida el refresh token en el backend (logout
  /// del lado del servidor se implementa si es necesario).
  Future<void> logout();

  /// Renueva los tokens usando [refreshToken].
  ///
  /// Retorna un nuevo [AuthResponse] con access y refresh
  /// tokens actualizados. Lanza [AuthException] si el
  /// refresh token expiró.
  Future<AuthResponse> refreshToken(String refreshToken);

  /// Verifica si hay una sesión activa localmente.
  ///
  /// Retorna `true` si existen tokens locales válidos.
  /// NO verifica si los tokens están expirados — eso
  /// se maneja automáticamente en AuthInterceptor.
  Future<bool> isLoggedIn();
}
