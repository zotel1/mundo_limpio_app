// Pruebas unitarias para AuthValidators.
// Verifica las reglas de validación de formularios de autenticación.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/auth/presentation/helpers/validators.dart';

void main() {
  group('AuthValidators.validateEmail', () {
    test('should return null for valid email', () {
      expect(AuthValidators.validateEmail('test@example.com'), isNull);
    });

    test('should return error for null email', () {
      final result = AuthValidators.validateEmail(null);
      expect(result, contains('requerido'));
    });

    test('should return error for empty email', () {
      final result = AuthValidators.validateEmail('');
      expect(result, contains('requerido'));
    });

    test('should return error for invalid format', () {
      final result = AuthValidators.validateEmail('not-an-email');
      expect(result, contains('email válido'));
    });
  });

  group('AuthValidators.validatePassword', () {
    test('should return null for non-empty password', () {
      expect(AuthValidators.validatePassword('anypassword'), isNull);
    });

    test('should return error for null password', () {
      final result = AuthValidators.validatePassword(null);
      expect(result, contains('requerida'));
    });

    test('should return error for empty password', () {
      final result = AuthValidators.validatePassword('');
      expect(result, contains('requerida'));
    });
  });

  group('AuthValidators.validatePasswordStrength', () {
    // R5.3: "Abc123" → aceptado
    test('R5.3: should accept password with upper, lower and digit', () {
      expect(AuthValidators.validatePasswordStrength('Abc123'), isNull);
    });

    // R5.1: "abc123" → rechazado (sin mayúscula)
    test('R5.1: should reject password without uppercase', () {
      final result = AuthValidators.validatePasswordStrength('abc123');
      expect(result, contains('mayúsculas'));
    });

    // R5.2: "ABC123" → rechazado (sin minúscula)
    test('R5.2: should reject password without lowercase', () {
      final result = AuthValidators.validatePasswordStrength('ABC123');
      expect(result, contains('minúsculas'));
    });

    // Edge R5.4: "Ab1" → rechazado (corto)
    test('Edge R5.4: should reject password shorter than 6 chars', () {
      final result = AuthValidators.validatePasswordStrength('Ab1');
      expect(result, contains('6 caracteres'));
    });

    // Edge: null → requerido
    test('should return error for null password', () {
      final result = AuthValidators.validatePasswordStrength(null);
      expect(result, contains('requerida'));
    });

    // Edge: "" → requerido
    test('should return error for empty password', () {
      final result = AuthValidators.validatePasswordStrength('');
      expect(result, contains('requerida'));
    });

    // Triangulación: password sin dígitos
    test('should reject password without digits', () {
      final result = AuthValidators.validatePasswordStrength('AbcDef');
      expect(result, contains('números'));
    });

    // Triangulación: password compleja válida
    test('should accept complex valid password', () {
      expect(AuthValidators.validatePasswordStrength('Secure1Pass!'), isNull);
    });
  });

  group('AuthValidators.validateConfirmPassword', () {
    test('should return null when passwords match', () {
      expect(
        AuthValidators.validateConfirmPassword('Pass123', 'Pass123'),
        isNull,
      );
    });

    test('should return error when passwords do not match', () {
      final result = AuthValidators.validateConfirmPassword(
        'Pass123',
        'Other45',
      );
      expect(result, contains('no coinciden'));
    });

    test('should return error for null confirmation', () {
      final result = AuthValidators.validateConfirmPassword(null, 'Pass123');
      expect(result, contains('Confirmá'));
    });

    test('should return error for empty confirmation', () {
      final result = AuthValidators.validateConfirmPassword('', 'Pass123');
      expect(result, contains('Confirmá'));
    });
  });
}
