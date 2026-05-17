// Pruebas unitarias para LoginRequest.
// Verifica que el modelo se serializa correctamente a JSON
// para enviarlo en el body de POST /auth/login.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/auth/data/models/login_request.dart';

void main() {
  group('LoginRequest', () {
    // Verifica que toJson produce el mapa JSON con email y password
    test('toJson debe contener email y password', () {
      final request = LoginRequest(
        email: 'test@example.com',
        password: 'SecurePass123!',
      );

      final json = request.toJson();

      expect(json['email'], 'test@example.com');
      expect(json['password'], 'SecurePass123!');
    });

    // Verifica que fromJson construye el objeto desde un mapa JSON.
    // Útil si el servidor devuelve los mismos campos en una respuesta.
    test('fromJson debe crear LoginRequest con todos los campos', () {
      final json = {'email': 'user@domain.com', 'password': 'MyP@ssw0rd'};

      final result = LoginRequest.fromJson(json);

      expect(result.email, 'user@domain.com');
      expect(result.password, 'MyP@ssw0rd');
    });

    // Round-trip: fromJson → toJson debe preservar los datos.
    // Garantiza que serialización y deserialización son inversas.
    test('round-trip fromJson → toJson debe preservar los datos', () {
      final original = LoginRequest(
        email: 'roundtrip@test.com',
        password: 'RoundTripPass1',
      );

      final json = original.toJson();
      final restored = LoginRequest.fromJson(json);

      expect(restored.email, original.email);
      expect(restored.password, original.password);
    });

    // Triangulación: email con caracteres especiales
    test('debe aceptar email con puntos y símbolos', () {
      final request = LoginRequest(
        email: 'test.name+tag@example.co.uk',
        password: 'Complex-Pass_123',
      );

      final json = request.toJson();

      expect(json['email'], 'test.name+tag@example.co.uk');
    });

    // Triangulación: contraseña con caracteres especiales
    test('debe aceptar contraseña con caracteres especiales', () {
      final request = LoginRequest(
        email: 'test@test.com',
        password: r'P@ssw0rd!#$%',
      );

      final json = request.toJson();

      expect(json['password'], r'P@ssw0rd!#$%');
    });
  });
}
