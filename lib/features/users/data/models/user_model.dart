import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';

part 'user_model.g.dart';

/// DTO json_serializable que refleja la respuesta JSON del backend
/// para un usuario del sistema.
///
/// Ejemplo de JSON esperado:
/// ```json
/// {
///   "id": 1,
///   "username": "Usuario123",
///   "email": "user@email.com",
///   "roles": ["STOCK_MANAGER"],
///   "createdAt": "2026-05-25T..."
/// }
/// ```
@JsonSerializable()
class UserModel {
  final int id;
  final String username;
  final String email;
  final List<UserRole> roles;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.roles,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Convierte este DTO a la entidad de dominio [User].
  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      roles: roles,
      createdAt: createdAt,
    );
  }
}
