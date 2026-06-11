// Implementación del repositorio de usuarios.
//
// Wrapper sobre UsersApi que convierte modelos de datos a entidades
// del dominio y maneja errores de API.

import 'package:dio/dio.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/users/data/api/users_api.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';
import 'package:mundo_limpio_app/features/users/domain/repositories/i_users_repository.dart';

class UsersRepositoryImpl implements IUsersRepository {
  final UsersApi _api;

  UsersRepositoryImpl({required UsersApi api}) : _api = api;

  @override
  Future<List<User>> getUsers({CancelToken? cancelToken}) async {
    try {
      final models = await _api.getUsers(cancelToken: cancelToken);
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<User> getUser(int id, {CancelToken? cancelToken}) async {
    try {
      final model = await _api.getUser(id, cancelToken: cancelToken);
      return model.toEntity();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<User> updateRoles(
    int userId,
    Set<UserRole> roles, {
    CancelToken? cancelToken,
  }) async {
    try {
      final model = await _api.updateRoles(
        userId,
        roles,
        cancelToken: cancelToken,
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> resetPassword(
    int userId,
    String newPassword, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _api.resetPassword(userId, newPassword, cancelToken: cancelToken);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
