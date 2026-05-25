// Implementación del repositorio de usuarios.
//
// Wrapper sobre UsersApi que convierte modelos de datos a entidades
// del dominio y maneja errores de API.

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/users/data/api/users_api.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';
import 'package:mundo_limpio_app/features/users/domain/repositories/i_users_repository.dart';

class UsersRepositoryImpl implements IUsersRepository {
  final UsersApi _api;

  UsersRepositoryImpl({required UsersApi api}) : _api = api;

  @override
  Future<List<User>> getUsers() async {
    try {
      final models = await _api.getUsers();
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  @override
  Future<User> getUser(int id) async {
    try {
      final model = await _api.getUser(id);
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch user $id: $e');
    }
  }

  @override
  Future<User> updateRoles(int userId, Set<UserRole> roles) async {
    try {
      final model = await _api.updateRoles(userId, roles);
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update roles for user $userId: $e');
    }
  }

  @override
  Future<void> resetPassword(int userId, String newPassword) async {
    try {
      await _api.resetPassword(userId, newPassword);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to reset password for user $userId: $e');
    }
  }
}
