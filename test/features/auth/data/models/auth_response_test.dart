// Pruebas unitarias para AuthResponse.
// Verifica que el modelo se serializa/deserializa correctamente
// desde/hacia JSON usando json_serializable.
//
// También verifica que toEntity() extrae el userId correctamente:
// - Prioriza userId del JSON
// - Fallback a JwtDecoder.getUserId(accessToken)
// - Fallback final a 0
//
// TDD: RED — test escrito antes que la implementación

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';

/// Helper: construye un token JWT simulado con sub específico.
String _makeJwt(dynamic sub) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256"}'));
  final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': sub})));
  final sig = base64Url.encode(utf8.encode('fake'));
  return '$header.$payload.$sig';
}

void main() {
  // Datos de ejemplo representando una respuesta típica del backend
  final jsonValid = {
    'accessToken': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0',
    'refreshToken': 'dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4',
    'role': 'user',
    'username': 'testuser',
    'email': 'admin@limpieza.com',
    'roles': ['ROLE_ADMIN', 'ROLE_USER'],
    'createdAt': '2026-05-09T00:00:00.000',
  };

  group('AuthResponse', () {
    // Verifica que fromJson construye correctamente el objeto
    // con todos los campos mapeados desde el JSON
    test('fromJson debe crear AuthResponse con todos los campos (R2.1)', () {
      final result = AuthResponse.fromJson(jsonValid);

      expect(result.accessToken, jsonValid['accessToken']);
      expect(result.refreshToken, jsonValid['refreshToken']);
      expect(result.role, jsonValid['role']);
      expect(result.username, jsonValid['username']);
      expect(result.email, 'admin@limpieza.com');
      expect(result.roles, ['ROLE_ADMIN', 'ROLE_USER']);
      expect(result.createdAt, DateTime(2026, 5, 9));
    });

    // Verifica que toJson produce el mapa JSON correcto,
    // incluyendo la serialización de DateTime a String ISO 8601
    test('toJson debe producir el mapa JSON correcto', () {
      final authResponse = AuthResponse(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        role: 'admin',
        username: 'adminuser',
        email: 'admin@limpieza.com',
        roles: ['ROLE_ADMIN'],
        createdAt: DateTime(2026, 5, 9, 12, 30, 0),
      );

      final json = authResponse.toJson();

      expect(json['accessToken'], 'access-123');
      expect(json['refreshToken'], 'refresh-456');
      expect(json['role'], 'admin');
      expect(json['username'], 'adminuser');
      expect(json['email'], 'admin@limpieza.com');
      expect(json['roles'], ['ROLE_ADMIN']);
      expect(json['createdAt'], '2026-05-09T12:30:00.000');
    });

    // Round-trip: fromJson → toJson debe producir el mismo mapa original.
    // Verifica que serialización y deserialización son inversas.
    test('round-trip fromJson → toJson debe preservar los datos', () {
      final original = AuthResponse.fromJson(jsonValid);
      final json = original.toJson();
      final restored = AuthResponse.fromJson(json);

      expect(restored.accessToken, original.accessToken);
      expect(restored.refreshToken, original.refreshToken);
      expect(restored.role, original.role);
      expect(restored.username, original.username);
      expect(restored.createdAt, original.createdAt);
    });

    // Edge case: email ausente debe ser null, roles ausente debe
    // usar [role] como fallback (R2.1)
    test('fromJson debe usar [role] como fallback cuando roles es null', () {
      final json = {
        'accessToken': 'token',
        'refreshToken': 'refresh',
        'role': 'user',
        'username': 'test',
        'createdAt': '2026-05-09T00:00:00.000',
      };
      final result = AuthResponse.fromJson(json);

      expect(result.email, isNull);
      expect(result.roles, ['user']); // fallback de role
    });

    // Triangulación: fecha con diferente formato (sin milisegundos)
    test('fromJson debe parsear createdAt sin milisegundos', () {
      final json = Map<String, dynamic>.from(jsonValid);
      json['createdAt'] = '2026-01-15T08:00:00';

      final result = AuthResponse.fromJson(json);

      expect(result.createdAt, DateTime(2026, 1, 15, 8, 0, 0));
    });

    // Triangulación: strings vacíos en campos de texto
    test('fromJson debe aceptar strings vacíos en username y role', () {
      final json = Map<String, dynamic>.from(jsonValid);
      json['username'] = '';
      json['role'] = '';

      final result = AuthResponse.fromJson(json);

      expect(result.username, '');
      expect(result.role, '');
    });

    // Edge case: fecha nula no debería ser posible (createdAt es non-nullable)
    // pero verificamos que el campo existe como DateTime
    test('createdAt debe ser DateTime no nulo', () {
      final result = AuthResponse.fromJson(jsonValid);

      expect(result.createdAt, isA<DateTime>());
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Tests de toEntity() — extracción de userId
  //
  // Escenarios de la spec sprint-correcciones Task B:
  // ESC-HAPPY-B1, B2, B3, ESC-EDGE-B1, B2, B3
  // ═══════════════════════════════════════════════════════════
  group('AuthResponseMapper.toEntity() — userId', () {
    // ═══════════════════════════════════════════════════════════
    // ESC-HAPPY-B1: Backend envía userId en el JSON → se usa ese valor
    // ═══════════════════════════════════════════════════════════
    test('debe usar userId del JSON cuando está presente (ESC-HAPPY-B1)', () {
      final response = AuthResponse.fromJson({...jsonValid, 'userId': 42});

      final session = response.toEntity();

      expect(
        session.userId,
        42,
        reason: 'Debe usar el userId del response JSON',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // ESC-HAPPY-B2: Backend NO envía userId, pero JWT tiene sub
    // ═══════════════════════════════════════════════════════════
    test('debe extraer userId del JWT cuando el JSON no tiene userId '
        '(ESC-HAPPY-B2)', () {
      final token = _makeJwt(42);
      final response = AuthResponse.fromJson({
        ...jsonValid,
        'accessToken': token,
        // sin userId
      });

      final session = response.toEntity();

      expect(
        session.userId,
        42,
        reason: 'Debe extraer el userId del JWT payload',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // ESC-HAPPY-B3: Backend envía AMBOS → userId del JSON prioriza
    // ═══════════════════════════════════════════════════════════
    test('debe priorizar userId del JSON sobre el JWT '
        '(ESC-HAPPY-B3)', () {
      final token = _makeJwt(99);
      final response = AuthResponse.fromJson({
        ...jsonValid,
        'userId': 42,
        'accessToken': token,
      });

      final session = response.toEntity();

      expect(
        session.userId,
        42,
        reason: 'userId del JSON debe tener prioridad sobre JWT',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // ESC-EDGE-B1: JWT mal formado → userId = 0
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 con JWT mal formado (ESC-EDGE-B1)', () {
      final response = AuthResponse.fromJson({
        ...jsonValid,
        'accessToken': 'token_mal_formado',
        // sin userId
      });

      final session = response.toEntity();

      expect(
        session.userId,
        0,
        reason: 'JWT mal formado debe resultar en userId 0',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // ESC-EDGE-B2: JWT válido pero sin sub → userId = 0
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando el JWT no tiene sub (ESC-EDGE-B2)', () {
      final header = base64Url.encode(utf8.encode('{"alg":"HS256"}'));
      final payload = base64Url.encode(
        utf8.encode('{"name":"test","role":"admin"}'),
      );
      final sig = base64Url.encode(utf8.encode('fake'));
      final token = '$header.$payload.$sig';

      final response = AuthResponse.fromJson({
        ...jsonValid,
        'accessToken': token,
        // sin userId
      });

      final session = response.toEntity();

      expect(
        session.userId,
        0,
        reason: 'JWT sin sub debe resultar en userId 0',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // ESC-EDGE-B3: JWT con sub no numérico → userId = 0
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando sub no es numérico (ESC-EDGE-B3)', () {
      final token = _makeJwt('not_a_number');
      final response = AuthResponse.fromJson({
        ...jsonValid,
        'accessToken': token,
        // sin userId
      });

      final session = response.toEntity();

      expect(
        session.userId,
        0,
        reason: 'Sub no numérico debe resultar en userId 0 sin crash',
      );
    });

    // ═══════════════════════════════════════════════════════════
    // Caso: sin userId en JSON, sin accessToken (null) → userId 0
    // ═══════════════════════════════════════════════════════════
    test('debe retornar 0 cuando no hay userId ni accessToken', () {
      final response = AuthResponse.fromJson({
        ...jsonValid,
        'accessToken': '',
        // sin userId
      });

      final session = response.toEntity();

      expect(
        session.userId,
        0,
        reason: 'Sin userId ni JWT válido debe resultar en 0',
      );
    });
  });
}
