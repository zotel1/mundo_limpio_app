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
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get('/api/v1/users');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Obtiene un usuario por su ID.
  ///
  /// Endpoint: `GET /api/v1/users/{id}`
  Future<UserModel> getUser(int id) async {
    try {
      final response = await _dio.get('/api/v1/users/$id');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Actualiza los roles de un usuario (reemplazo completo).
  ///
  /// Endpoint: `PATCH /api/v1/users/{id}/roles`
  /// Body: `{ "roles": ["STOCK_MANAGER", "ADMIN"] }`
  Future<UserModel> updateRoles(int userId, Set<UserRole> roles) async {
    try {
      final response = await _dio.patch(
        '/api/v1/users/$userId/roles',
        data: {'roles': roles.map((r) => r.jsonValue).toList()},
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Resetea la contraseña de un usuario.
  ///
  /// Endpoint: `PATCH /api/v1/users/{id}/password`
  /// Body: `{ "newPassword": "nueva-contraseña" }`
  Future<void> resetPassword(int userId, String newPassword) async {
    try {
      await _dio.patch(
        '/api/v1/users/$userId/password',
        data: {'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }
}
