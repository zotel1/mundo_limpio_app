// Almacenamiento seguro de tokens JWT.
//
// Wrapper sobre FlutterSecureStorage que centraliza
// las claves usadas y expone una interfaz simple:
// saveTokens, readTokens, clear, hasTokens.
//
// Principio: los tokens deben persistir entre reinicios
// de la app (R1.1) y nunca almacenarse en texto plano.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Par de tokens (access + refresh) retornado por [readTokens].
///
/// `null` significa que no hay sesión activa (R1.2).
typedef TokenPair = ({String access, String refresh});

/// Wrapper tipado sobre FlutterSecureStorage para tokens JWT.
///
/// Recibe opcionalmente una instancia de [FlutterSecureStorage]
/// para facilitar tests (inyección de dependencias).
/// Si no se provee, usa una instancia por defecto.
class TokenStorage {
  /// Clave para el access token en el storage.
  static const _accessTokenKey = 'access_token';

  /// Clave para el refresh token en el storage.
  static const _refreshTokenKey = 'refresh_token';

  /// Clave para la lista de roles en el storage.
  static const _rolesListKey = 'roles_list';

  /// Clave para el nombre de usuario en el storage.
  static const _usernameKey = 'username';

  /// Clave para el email en el storage.
  static const _emailKey = 'email';

  /// Instancia de FlutterSecureStorage (real o mockeada en tests).
  final FlutterSecureStorage _storage;

  /// Crea un [TokenStorage] con la [storage] opcional.
  ///
  /// Si no se provee [storage], usa `const FlutterSecureStorage()`.
  /// En tests se pasa un mock para evitar dependencia del Keychain.
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Guarda el [access] token y [refresh] token en el storage seguro.
  ///
  /// Ambos se persisten con claves separadas para permitir
  /// lectura individual o borrado atómico.
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  /// Lee ambos tokens del storage.
  ///
  /// Retorna un [TokenPair] si existen AMBOS tokens,
  /// o `null` si falta alguno (R1.2).
  ///
  /// Si solo existe uno de los dos, retorna `null` porque
  /// el estado es inconsistente (no debería ocurrir en
  /// condiciones normales).
  Future<TokenPair?> readTokens() async {
    final access = await _storage.read(key: _accessTokenKey);
    final refresh = await _storage.read(key: _refreshTokenKey);

    // Solo retorna tokens si AMBOS existen
    if (access == null || refresh == null) return null;

    return (access: access, refresh: refresh);
  }

  /// Guarda la lista de roles del usuario en el storage seguro.
  Future<void> saveRoles(List<String> roles) async {
    await _storage.write(key: _rolesListKey, value: roles.join(','));
  }

  /// Lee la lista de roles del storage.
  ///
  /// Retorna `null` si no hay roles guardados.
  Future<List<String>?> readRoles() async {
    final value = await _storage.read(key: _rolesListKey);
    if (value == null || value.isEmpty) return null;
    return value.split(',');
  }

  /// Guarda el nombre de usuario en el storage seguro.
  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  /// Lee el nombre de usuario del storage.
  ///
  /// Retorna `null` si no hay username guardado.
  Future<String?> readUsername() async {
    return _storage.read(key: _usernameKey);
  }

  /// Guarda el email del usuario en el storage seguro.
  Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  /// Lee el email del storage.
  ///
  /// Retorna `null` si no hay email guardado.
  Future<String?> readEmail() async {
    return _storage.read(key: _emailKey);
  }

  /// Elimina TODOS los tokens del storage seguro.
  ///
  /// Se usa en logout (R5.1) y cuando el refresh falla (R4.2).
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Elimina TODOS los datos del storage seguro (tokens + metadata).
  ///
  /// Se usa en logout completo del AuthProvider.
  Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _rolesListKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _emailKey);
  }

  /// Verifica si existen AMBOS tokens en el storage.
  ///
  /// Retorna `true` solo si access_token Y refresh_token existen.
  /// Si falta alguno, retorna `false` (estado inconsistente).
  Future<bool> hasTokens() async {
    final hasAccess = await _storage.containsKey(key: _accessTokenKey);
    final hasRefresh = await _storage.containsKey(key: _refreshTokenKey);
    return hasAccess && hasRefresh;
  }
}
