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
    // AuthException debe mostrar mensaje de "No autorizado"
    test('should return "No autorizado" for AuthException', () {
      final exception = AuthException('No autorizado');
      final result = ErrorHandler.getMessage(exception);

      expect(result, contains('No autorizado'));
      expect(result, contains('iniciá sesión'));
    });

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

      expect(result, contains('Error inesperado'));
    });

    // Triangulación: AuthException con diferentes mensajes
    test('should return auth message even with custom AuthException message', () {
      final exception = AuthException('Custom auth error');
      final result = ErrorHandler.getMessage(exception);

      // Debe ignorar el mensaje custom y devolver el mensaje estándar de auth
      expect(result, contains('No autorizado'));
    });

    // Triangulación: ServerException con código 502
    test('should return server error message for any ServerException', () {
      final exception = ServerException('Error 502 Bad Gateway');
      final result = ErrorHandler.getMessage(exception);

      expect(result, contains('Error interno del servidor'));
    });
  });
}
