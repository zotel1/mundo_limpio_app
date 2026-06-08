// Pruebas unitarias para ErrorHandler.
// Verifica que cada tipo de ApiException se mapee a un mensaje
// en español legible para el usuario.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/network/error_handler.dart';

void main() {
  group('ErrorHandler.getMessage', () {
    // AuthException con mensaje default debe mostrar mensaje de "No autorizado"
    test(
      'should return "No autorizado" for AuthException with default message',
      () {
        final exception = AuthException(
          'No autorizado. Iniciá sesión nuevamente.',
        );
        final result = ErrorHandler.getMessage(exception);

        expect(result, contains('No autorizado'));
        expect(result, contains('iniciá sesión'));
      },
    );

    // AuthException con mensaje del backend: backend wins
    test(
      'should return backend message for AuthException with custom message',
      () {
        final exception = AuthException('Email o contraseña incorrectos');
        final result = ErrorHandler.getMessage(exception);

        expect(result, 'Email o contraseña incorrectos');
      },
    );

    // NetworkException debe mostrar mensaje de "Sin conexión"
    test('should return "Sin conexión a internet" for NetworkException', () {
      final exception = NetworkException('Sin conexión a internet');
      final result = ErrorHandler.getMessage(exception);

      expect(result, contains('Sin conexión a internet'));
      expect(result, contains('verificá tu conexión'));
    });

    // ServerException debe mostrar mensaje de error interno
    test('should return "Error interno del servidor" for ServerException', () {
      final exception = ServerException('Error interno del servidor');
      final result = ErrorHandler.getMessage(exception);

      expect(result, contains('Error interno del servidor'));
      expect(result, contains('más tarde'));
    });

    // ApiException genérica debe mostrar el mensaje original
    test('should return original message for generic ApiException', () {
      const exception = ApiException('Error personalizado', 418);
      final result = ErrorHandler.getMessage(exception);

      expect(result, 'Error personalizado');
    });

    // ApiException con mensaje vacío debe mostrar fallback genérico
    test('should return fallback message for empty ApiException', () {
      const exception = ApiException('', 0);
      final result = ErrorHandler.getMessage(exception);

      expect(result, 'Error inesperado. Intentalo de nuevo.');
    });

    // R3.1: ConflictException con mensaje del backend (no-default) → backend wins
    test(
      'R3.1: should return backend message for ConflictException with non-default message',
      () {
        final exception = ConflictException('El email ya está registrado');
        final result = ErrorHandler.getMessage(exception);

        expect(result, 'El email ya está registrado');
      },
    );

    // R3.2: ConflictException con mensaje default → mapeo por subtipo
    test(
      'R3.2: should return subtype mapping for ConflictException with default message',
      () {
        final exception = ConflictException('Error de conflicto (409).');
        final result = ErrorHandler.getMessage(exception);

        expect(result, 'El recurso ya existe.');
      },
    );

    // R3.3: ApiException con mensaje vacío → fallback genérico
    test('R3.3: should return generic fallback for empty ApiException', () {
      const exception = ApiException('', 0);
      final result = ErrorHandler.getMessage(exception);

      expect(result, 'Error inesperado. Intentalo de nuevo.');
    });

    // Triangulación: ValidationException con mensaje default
    test(
      'should return subtype mapping for ValidationException with default message',
      () {
        final exception = ValidationException('Error de validación (400).');
        final result = ErrorHandler.getMessage(exception);

        expect(result, 'Verificá los datos ingresados.');
      },
    );

    // Triangulación: ValidationException con mensaje del backend
    test(
      'should return backend message for ValidationException with non-default message',
      () {
        final exception = ValidationException('Contraseña muy débil');
        final result = ErrorHandler.getMessage(exception);

        expect(result, 'Contraseña muy débil');
      },
    );

    // Triangulación: RateLimitException con mensaje default
    test(
      'should return subtype mapping for RateLimitException with default message',
      () {
        final exception = RateLimitException('Demasiados intentos (429).');
        final result = ErrorHandler.getMessage(exception);

        expect(result, 'Demasiados intentos. Esperá un momento.');
      },
    );

    // Triangulación: RateLimitException con mensaje del backend
    test(
      'should return backend message for RateLimitException with non-default message',
      () {
        final exception = RateLimitException(
          'Límite excedido, intentá en 30 segundos',
        );
        final result = ErrorHandler.getMessage(exception);

        expect(result, 'Límite excedido, intentá en 30 segundos');
      },
    );

    // Triangulación: AuthException con mensaje default de 403
    test(
      'should return "No autorizado" for AuthException with 403 default message',
      () {
        final exception = AuthException(
          'Acceso denegado. No tenés permisos para esta acción.',
        );
        final result = ErrorHandler.getMessage(exception);

        expect(result, contains('No autorizado'));
      },
    );
  });
}
