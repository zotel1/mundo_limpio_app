// Pruebas unitarias para AuthResponse.
// Verifica que el modelo se serializa/deserializa correctamente
// desde/hacia JSON usando json_serializable.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';

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

    // Edge case: email y roles ausentes deben ser null
    test('fromJson debe manejar email y roles ausentes como null', () {
      final json = {
        'accessToken': 'token',
        'refreshToken': 'refresh',
        'role': 'user',
        'username': 'test',
        'createdAt': '2026-05-09T00:00:00.000',
      };
      final result = AuthResponse.fromJson(json);

      expect(result.email, isNull);
      expect(result.roles, isNull);
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
}
