import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// Entidad de dominio que representa un usuario del sistema.
class User extends Equatable {
  final int id;
  final String username;
  final String email;
  final List<UserRole> roles;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.roles,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, username, email, roles, createdAt];
}
