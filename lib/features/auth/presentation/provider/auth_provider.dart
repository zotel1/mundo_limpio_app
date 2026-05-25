// Provider de autenticación para la capa de presentación.
//
// Wrapper sobre AuthRepository que expone el estado de autenticación
// como ChangeNotifier para que los widgets se reconstruyan
// reactivamente cuando el estado cambia.
//
// Estados posibles:
// - loading: resolviendo autenticación inicial (checkAuth) o en progreso
// - authenticated: sesión activa con tokens válidos
// - unauthenticated: sin sesión activa o error de autenticación
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/crashlytics/crashlytics_service.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/network/error_handler.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';

/// Estados posibles del flujo de autenticación.
///
/// - [loading]: estado inicial o mientras se procesa una operación
/// - [authenticated]: usuario autenticado con tokens válidos
/// - [unauthenticated]: sin sesión activa
enum AuthStatus { loading, authenticated, unauthenticated }

/// Provider de autenticación que coordina el estado global.
///
/// Usa [AuthRepository] para las operaciones de autenticación
/// y expone el estado via ChangeNotifier para la UI reactiva.
///
/// Cada método:
/// 1. Setea loading y notifica
/// 2. Ejecuta la operación (try)
/// 3. Setea status/error y notifica
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.loading;
  String? _error;

  /// Rol del usuario autenticado (null si no hay sesión activa).
  String? _role;

  /// Email del usuario autenticado (null si no hay sesión activa).
  String? _email;

  /// Roles del usuario autenticado (null si no hay sesión activa).
  List<String>? _roles;

  /// Nombre de usuario autenticado (null si no hay sesión activa).
  ///
  /// Se usa como identificador para Crashlytics (setUserIdentifier).
  String? _username;

  /// Estado actual de autenticación.
  AuthStatus get status => _status;

  /// Mensaje de error actual (null si no hay error).
  String? get error => _error;

  /// True mientras se está resolviendo una operación.
  bool get isLoading => _status == AuthStatus.loading;

  /// True si hay una sesión activa.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Rol del usuario autenticado.
  ///
  /// Retorna null si no hay sesión activa (estado inicial o después de logout).
  /// Se popula después de un login exitoso desde [AuthResponse.role].
  /// T-5.3 lo usa para mostrar botones condicionales según el rol.
  ///
  /// Si el backend envía múltiples roles via [roles], retorna el primero
  /// como rol principal para mantener compatibilidad con [role] getter.
  String? get role => _roles?.first ?? _role;

  /// Email del usuario autenticado (null si no hay sesión activa).
  String? get email => _email;

  /// Roles completos del usuario autenticado (null si no hay sesión activa).
  List<String>? get roles => _roles;

  /// Nombre de usuario autenticado.
  ///
  /// Retorna null si no hay sesión activa.
  /// Se usa para Crashlytics.setUserIdentifier en el reporte de crashes.
  String? get username => _username;

  /// Crea un [AuthProvider] con el [repository] inyectado.
  AuthProvider(this._repository);

  /// Verifica si hay tokens locales al iniciar la app.
  ///
  /// Se llama desde el splash screen o desde el redirect de go_router.
  /// Usa [AuthRepository.isLoggedIn] para determinar el estado inicial.
  Future<void> checkAuth() async {
    _setLoading();
    try {
      final loggedIn = await _repository.isLoggedIn();
      _status = loggedIn
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      _error = null;
    } catch (_) {
      // Si falla la verificación (ej: storage corrupto),
      // tratar como no autenticado
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Autentica al usuario con [email] y [password].
  ///
  /// En caso de éxito: status = authenticated (R3.1).
  /// En caso de error: status = unauthenticated con mensaje (R3.2, R3.3).
  Future<void> login(String email, String password) async {
    _setLoading();
    try {
      final response = await _repository.login(email, password);
      _role = response.role;
      _email = response.email;
      _roles = response.roles;
      _username = response.username;
      _status = AuthStatus.authenticated;
      _error = null;

      // Vincular metadata de usuario a Crashlytics para diagnósticos
      // TDD: GREEN — el try-catch en setUser() protege si Firebase no está disponible
      CrashlyticsService.setUser(response.username, response.role);
    } on ApiException catch (e) {
      // ApiException tiene mensaje amigable via ErrorHandler
      _role = null;
      _email = null;
      _roles = null;
      _username = null;
      _error = ErrorHandler.getMessage(e);
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      // Error genérico (no debería ocurrir en condiciones normales)
      _role = null;
      _email = null;
      _roles = null;
      _username = null;
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Registra un nuevo usuario con [email] y [password].
  ///
  /// En caso de éxito: status = unauthenticated (redirige a login, R2.1).
  /// En caso de error: status = unauthenticated con mensaje (R2.2).
  Future<void> register(String email, String password) async {
    _setLoading();
    try {
      await _repository.register(email, password);
      // No autenticar automáticamente — el usuario debe
      // iniciar sesión después del registro (R2.1)
      _status = AuthStatus.unauthenticated;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Cierra la sesión: limpia tokens y desautentica (R5.1).
  Future<void> logout() async {
    _setLoading();
    try {
      await _repository.logout();
    } catch (_) {
      // Si falla el logout, igual desautenticamos al usuario
      // para no quedar en un estado inconsistente
    }
    _status = AuthStatus.unauthenticated;
    _role = null;
    _email = null;
    _roles = null;
    _username = null;
    _error = null;

    // Desvincular metadata de usuario de Crashlytics
    CrashlyticsService.setUser('', '');

    notifyListeners();
  }

  /// Limpia el mensaje de error actual.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Setea estado a loading y notifica.
  void _setLoading() {
    _status = AuthStatus.loading;
    notifyListeners();
  }
}
