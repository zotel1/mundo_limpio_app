// Pruebas unitarias para RegisterRequest.
// Verifica que el modelo se serializa correctamente a JSON
// para enviarlo en el body de POST /auth/register.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/auth/data/models/register_request.dart';

void main() {
  group('RegisterRequest', () {
    // Verifica que toJson produce el mapa JSON con email y password
    test('toJson debe contener email y password', () {
      final request = RegisterRequest(
        email: 'newuser@example.com',
        password: 'StrongP@ss1',
      );

      final json = request.toJson();

      expect(json['email'], 'newuser@example.com');
      expect(json['password'], 'StrongP@ss1');
    });

    // Verifica que fromJson construye el objeto desde un mapa JSON.
    test('fromJson debe crear RegisterRequest con todos los campos', () {
      final json = {'email': 'register@domain.com', 'password': 'RegP@ss789'};

      final result = RegisterRequest.fromJson(json);

      expect(result.email, 'register@domain.com');
      expect(result.password, 'RegP@ss789');
    });

    // Round-trip: fromJson → toJson debe preservar los datos.
    test('round-trip fromJson → toJson debe preservar los datos', () {
      final original = RegisterRequest(
        email: 'rt@test.com',
        password: 'RoundTrip789!',
      );

      final json = original.toJson();
      final restored = RegisterRequest.fromJson(json);

      expect(restored.email, original.email);
      expect(restored.password, original.password);
    });

    // Triangulación: email con formato largo
    test('debe aceptar email largo con múltiples dominios', () {
      final request = RegisterRequest(
        email: 'very.long.email.address@sub.domain.co.uk',
        password: 'LongEmailPass1',
      );

      final json = request.toJson();

      expect(json['email'], 'very.long.email.address@sub.domain.co.uk');
    });

    // Triangulación: contraseña corta (la validación se hace en UI,
    // el modelo solo transporta datos)
    test('debe aceptar contraseña corta (sin validación en modelo)', () {
      final request = RegisterRequest(email: 'test@test.com', password: 'ab');

      final json = request.toJson();

      expect(json['password'], 'ab');
    });
  });
}
