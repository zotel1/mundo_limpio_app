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

  /// Elimina TODOS los tokens del storage seguro.
  ///
  /// Se usa en logout (R5.1) y cuando el refresh falla (R4.2).
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
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
