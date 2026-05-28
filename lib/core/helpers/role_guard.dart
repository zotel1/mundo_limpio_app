// Helper estático para verificar roles de usuario.
//
// Proporciona un método simple para comprobar si un usuario
// tiene al menos uno de los roles requeridos.

class RoleGuard {
  /// Retorna `true` si [roles] contiene al menos uno de los roles en [required].
  ///
  /// Si [roles] es `null` o está vacío, retorna `false`.
  static bool hasAnyRole(List<String>? roles, List<String> required) {
    if (roles == null || roles.isEmpty) return false;
    return roles.any((r) => required.contains(r));
  }
}
