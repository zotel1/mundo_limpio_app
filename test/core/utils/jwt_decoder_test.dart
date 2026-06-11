// Pruebas unitarias para JwtDecoder.getUserId().
//
// Verifica la extracción del userId desde el payload JWT
// en todos los escenarios definidos en la spec:
// ESC-HAPPY-B2, ESC-EDGE-B1, ESC-EDGE-B2, ESC-EDGE-B3, ESC-ERROR-B1
//
// TDD: RED — test escrito antes que la implementación

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/core/utils/jwt_decoder.dart';

/// Helper: construye un token JWT simulado con 3 partes.
///
/// El header y signature son placeholders fake — solo nos interesa
/// el payload (parte del medio) para extraer el userId.
String _makeToken(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final signature = base64Url.encode(utf8.encode('fake-signature'));
  return '$header.$body.$signature';
}

void main() {
  group('JwtDecoder.getUserId', () {
    // ═══════════════════════════════════════════════════════════
    // ESC-HAPPY-B2: JWT válido con sub: 42 (int)
    // ═══════════════════════════════════════════════════════════
    test(
      'debe retornar el userId cuando sub es un entero (ESC-HAPPY-B2 int)',
      () {
        final token = _makeToken({'sub': 42, 'name': 'Test User'});

        final result = JwtDecoder.getUserId(token);

        expect(result, 42, reason: 'Debe extraer el int del campo sub');
      },
    );

    // ═══════════════════════════════════════════════════════════
    // Triangulación: sub como string numérico "42"
    // ═══════════════════════════════════════════════════════════
    test('debe retornar el userId cuando sub es string numérico "42"', () {
      final token = _makeToken({'sub': '42', 'name': 'Test User'});

      final result = JwtDecoder.getUserId(token);

      expect(
        result,
        42,
        reason: 'Debe parsear el string numérico del campo sub',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // ESC-EDGE-B1: JWT mal formado (no tiene 3 partes)
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando el token no tiene 3 partes (ESC-EDGE-B1)', () {
      const token = 'soloDosPartes.estoNoEsUnJWT';

      final result = JwtDecoder.getUserId(token);

      expect(result, 0, reason: 'Token mal formado debe retornar 0');
    });

    // ═══════════════════════════════════════════════════════════
    // Triangulación: token con solo 1 parte
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando el token tiene solo 1 parte', () {
      const token = 'unaSolaParte';

      final result = JwtDecoder.getUserId(token);

      expect(result, 0, reason: 'Token con una sola parte debe retornar 0');
    });

    // ═══════════════════════════════════════════════════════════
    // ESC-EDGE-B2: JWT válido pero sin campo sub ni userId
    // ═══════════════════════════════════════════════════════════
    test(
      'debe retornar 0 cuando el payload no tiene sub ni userId (ESC-EDGE-B2)',
      () {
        final token = _makeToken({'name': 'Test', 'role': 'admin'});

        final result = JwtDecoder.getUserId(token);

        expect(
          result,
          0,
          reason: 'Payload sin sub debe retornar 0 como fallback',
        );
      },
    );

    // ═══════════════════════════════════════════════════════════
    // ESC-EDGE-B3: JWT con sub no numérico (string "not_a_number")
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando sub no es un número válido (ESC-EDGE-B3)', () {
      final token = _makeToken({'sub': 'not_a_number'});

      final result = JwtDecoder.getUserId(token);

      expect(
        result,
        0,
        reason: 'Sub no numérico debe retornar 0 sin lanzar excepción',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // ESC-ERROR-B1: token null → userId = 0
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando el token es null', () {
      final result = JwtDecoder.getUserId(null);

      expect(
        result,
        0,
        reason: 'Token null debe retornar 0 como fallback seguro',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // Triangulación extra: payload no es JSON válido
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando el payload no es JSON válido', () {
      // Construir token con payload base64 que no decodifica a JSON
      final badPayload = base64Url.encode(utf8.encode('esto no es json'));
      final token = 'header.$badPayload.signature';

      final result = JwtDecoder.getUserId(token);

      expect(result, 0, reason: 'Payload no-JSON debe retornar 0 sin crash');
    });

    // ═══════════════════════════════════════════════════════════
    // Triangulación extra: token vacío
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando el token es vacío', () {
      const token = '';

      final result = JwtDecoder.getUserId(token);

      expect(result, 0, reason: 'Token vacío debe retornar 0');
    });
  });
}
