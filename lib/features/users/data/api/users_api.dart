// Capa de comunicación HTTP para el módulo de Usuarios (admin).
//
// Implementa las 4 llamadas a los endpoints de usuarios del backend:
// - GET    /api/v1/users            (listar todos)
// - GET    /api/v1/users/{id}       (obtener por ID)
// - PATCH  /api/v1/users/{id}/roles    (actualizar roles)
// - PATCH  /api/v1/users/{id}/password (resetear contraseña)
//
// Recibe una instancia de Dio inyectada (sin crearla internamente)
// para permitir tests con mocks y compartir la configuración
// de ApiClient (base URL, timeouts, interceptors).

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/users/data/models/user_model.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';

/// Cliente HTTP para los endpoints de administración de usuarios.
///
/// Cada método retorna su tipo correspondiente o lanza [ApiException]
/// (o subtipo) en caso de error.
class UsersApi {
  final Dio _dio;

  const UsersApi({required Dio dio}) : _dio = dio;

  /// Obtiene la lista completa de usuarios.
  ///
  /// Endpoint: `GET /api/v1/users`
  Future<List<UserModel>> getUsers({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        '/api/v1/users',
        cancelToken: cancelToken,
      );
      final data = response.data['content'] as List<dynamic>;
      return data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Obtiene un usuario por su ID.
  ///
  /// Endpoint: `GET /api/v1/users/{id}`
  Future<UserModel> getUser(int id, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        '/api/v1/users/$id',
        cancelToken: cancelToken,
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Actualiza los roles de un usuario (reemplazo completo).
  ///
  /// Endpoint: `PATCH /api/v1/users/{id}/roles`
  /// Body: `{ "roles": ["STOCK_MANAGER", "ADMIN"] }`
  Future<UserModel> updateRoles(
    int userId,
    Set<UserRole> roles, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/v1/users/$userId/roles',
        data: {'roles': roles.map((r) => r.jsonValue).toList()},
        cancelToken: cancelToken,
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Resetea la contraseña de un usuario.
  ///
  /// Endpoint: `PATCH /api/v1/users/{id}/password`
  /// Body: `{ "newPassword": "nueva-contraseña" }`
  Future<void> resetPassword(
    int userId,
    String newPassword, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.patch(
        '/api/v1/users/$userId/password',
        data: {'newPassword': newPassword},
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
