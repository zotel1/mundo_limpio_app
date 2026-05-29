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

  /// Retorna `true` si [roles] permite acceder a [path] según [routeMap].
  ///
  /// Itera [routeMap] en orden de inserción. Si [path] comienza con una clave
  /// del mapa, verifica que [roles] contenga al menos uno de los valores.
  /// Si ninguna clave coincide, la ruta es pública (retorna `true`).
  static bool isRouteAllowed(
    List<String>? roles,
    String path,
    Map<String, Set<String>> routeMap,
  ) {
    if (roles == null || roles.isEmpty) return false;
    for (final entry in routeMap.entries) {
      if (path.startsWith(entry.key)) {
        return roles.any((r) => entry.value.contains(r));
      }
    }
    return true; // ruta no mapeada → pública
  }
}
