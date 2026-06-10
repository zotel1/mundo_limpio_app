// Provider de estado para la gestión de usuarios (admin).
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Expone el estado de operaciones de administración de usuarios
// como ChangeNotifier para que los widgets se reconstruyan reactivamente.
//
// Estados posibles:
// - initial: estado inicial, sin operaciones
// - loading: operación de carga en progreso
// - loaded: operación exitosa con datos
// - error: operación fallida con mensaje de error
// - updatingRole: actualización de roles en progreso
// - resettingPassword: reseteo de contraseña en progreso

import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/network/error_handler.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';
import 'package:mundo_limpio_app/features/users/domain/repositories/i_users_repository.dart';

/// Estados posibles del flujo de Usuarios.
///
/// - [initial]: estado inicial, sin operaciones realizadas
/// - [loading]: mientras se ejecuta una carga
/// - [loaded]: operación exitosa con datos disponibles
/// - [error]: operación fallida con mensaje de error
/// - [updatingRole]: actualización de roles en progreso
/// - [resettingPassword]: reseteo de contraseña en progreso
enum UsersStatus {
  initial,
  loading,
  loaded,
  error,
  updatingRole,
  resettingPassword,
}

/// Provider de estado para Usuarios (admin).
///
/// Usa [IUsersRepository] para las operaciones de administración
/// y expone el estado via ChangeNotifier para la UI reactiva.
///
/// Cada método:
/// 1. Setea estado operativo y notifica
/// 2. Ejecuta la operación (try)
/// 3. Setea status/error y notifica
class UsersProvider extends ChangeNotifier {
  final IUsersRepository _repository;

  UsersStatus _status = UsersStatus.initial;
  String? _error;
  List<User> _users = [];
  User? _selectedUser;

  /// Estado actual de las operaciones.
  UsersStatus get status => _status;

  /// Mensaje de error actual (null si no hay error).
  String? get error => _error;

  /// Lista de usuarios.
  ///
  /// Retorna una copia inmutable para evitar mutaciones externas.
  List<User> get users => List.unmodifiable(_users);

  /// Usuario seleccionado (cargado via loadUser).
  User? get selectedUser => _selectedUser;

  /// True mientras se está cargando.
  bool get isLoading =>
      _status == UsersStatus.loading ||
      _status == UsersStatus.updatingRole ||
      _status == UsersStatus.resettingPassword;

  /// Crea un [UsersProvider] con el [repository] inyectado.
  UsersProvider(this._repository);

  /// Obtiene la lista completa de usuarios.
  ///
  /// En caso de éxito: status = loaded, users = lista obtenida.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> loadUsers() async {
    _status = UsersStatus.loading;
    notifyListeners();
    try {
      _users = await _repository.getUsers();
      _status = UsersStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = UsersStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = UsersStatus.error;
    }
    notifyListeners();
  }

  /// Obtiene un usuario por su ID y lo setea como selectedUser.
  Future<void> loadUser(int id) async {
    _status = UsersStatus.loading;
    notifyListeners();
    try {
      _selectedUser = await _repository.getUser(id);
      _status = UsersStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = UsersStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = UsersStatus.error;
    }
    notifyListeners();
  }

  /// Actualiza los roles de un usuario (reemplazo completo).
  ///
  /// En caso de éxito: recarga el usuario y status = loaded.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> updateRoles(int userId, Set<UserRole> roles) async {
    _status = UsersStatus.updatingRole;
    notifyListeners();
    try {
      _selectedUser = await _repository.updateRoles(userId, roles);
      _status = UsersStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = UsersStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = UsersStatus.error;
    }
    notifyListeners();
  }

  @override
  // ignore: unnecessary_overrides
  void dispose() {
    super.dispose();
  }

  /// Resetea la contraseña de un usuario.
  ///
  /// En caso de éxito: status = loaded (mantiene el usuario actual).
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> resetPassword(int userId, String newPassword) async {
    _status = UsersStatus.resettingPassword;
    notifyListeners();
    try {
      await _repository.resetPassword(userId, newPassword);
      _status = UsersStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = UsersStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = UsersStatus.error;
    }
    notifyListeners();
  }
}
