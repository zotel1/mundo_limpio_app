// Utilidad para decodificar el payload de un JWT y extraer información.
//
// Los tokens JWT constan de 3 partes separadas por punto:
// header.payload.signature, cada una en base64url.
// Solo decodificamos el payload (parte del medio) para extraer claims.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'dart:convert';

/// Decodifica claims del payload JWT sin verificar firma.
///
/// Proporciona métodos estáticos para extraer claims comunes
/// de tokens JWT. No valida la firma — eso lo hace el backend.
/// Solo decodifica el payload base64url.
class JwtDecoder {
  JwtDecoder._(); // Clase de utilidad, no instanciable

  /// Extrae el userId del claim `sub` en el payload JWT.
  ///
  /// El claim `sub` (subject) en JWT es un string según RFC 7519,
  /// pero algunos backends envían un entero. Esta función soporta ambos.
  ///
  /// Retorna 0 (fallback seguro) en cualquier caso de error:
  /// - Token null o vacío
  /// - Token mal formado (no tiene 3 partes separadas por '.')
  /// - Payload no es base64 válido
  /// - Payload no es JSON válido
  /// - Payload no contiene el claim `sub`
  /// - `sub` no es un número válido (int o string numérico)
  ///
  /// Nunca lanza excepción — siempre retorna un valor seguro.
  static int getUserId(String? token) {
    try {
      if (token == null || token.isEmpty) return 0;

      final parts = token.split('.');
      if (parts.length != 3) return 0;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload) as Map<String, dynamic>;

      final sub = json['sub'];
      if (sub == null) return 0;

      // sub puede ser int o string según el backend
      if (sub is int) return sub;
      if (sub is String) return int.tryParse(sub) ?? 0;

      return 0; // sub es de un tipo inesperado
    } catch (_) {
      return 0; // fallback seguro para cualquier error
    }
  }
}
