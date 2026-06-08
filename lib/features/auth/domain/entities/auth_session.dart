// Entidad de dominio que representa una sesión de autenticación.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y enums puros.

/// Sesión de autenticación del usuario actual.
///
/// Contiene la información esencial del usuario autenticado:
/// ID, username, email opcional y lista de roles.
class AuthSession {
  /// ID único del usuario.
  final int userId;

  /// Nombre de usuario visible en la UI.
  final String username;

  /// Email del usuario (opcional).
  final String? email;

  /// Roles del usuario (fuente de verdad para autorización).
  final List<String> roles;

  /// Crea un [AuthSession] con todos los campos requeridos.
  const AuthSession({
    required this.userId,
    required this.username,
    this.email,
    required this.roles,
  });

  /// Retorna una copia con los campos indicados reemplazados.
  AuthSession copyWith({
    int? userId,
    String? username,
    String? email,
    List<String>? roles,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      roles: roles ?? this.roles,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSession &&
        other.userId == userId &&
        other.username == username &&
        other.email == email &&
        _listEquals(other.roles, roles);
  }

  @override
  int get hashCode =>
      Object.hash(userId, username, email, Object.hashAll(roles));

  @override
  String toString() =>
      'AuthSession(userId: $userId, username: $username, '
      'email: $email, roles: $roles)';
}

bool _listEquals(List<dynamic>? a, List<dynamic>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
