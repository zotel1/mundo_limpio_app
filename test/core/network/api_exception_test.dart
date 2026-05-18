// Pruebas unitarias para la jerarquía de ApiException.
// Verifica la propagación de mensajes, códigos de error,
// subtipos y el factory method fromStatusCode.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';

void main() {
  group('ApiException (base)', () {
    test('should store message and code', () {
      final exception = ApiException('Error genérico', 500);
      expect(exception.message, 'Error genérico');
      expect(exception.code, 500);
    });

    test('should implement Exception interface', () {
      final exception = ApiException('test', 0);
      expect(exception, isA<Exception>());
    });
  });

  group('AuthException', () {
    // AuthException representa errores 401 (no autorizado).
    // El código 401 es fijo porque siempre indica falta de autenticación.
    test('should have fixed code 401', () {
      final exception = AuthException('Token expirado');
      expect(exception.code, 401);
      expect(exception.message, 'Token expirado');
    });

    // Verifica la relación de herencia: AuthException IS-A ApiException
    test('should be subtype of ApiException', () {
      expect(AuthException('test'), isA<ApiException>());
    });
  });

  group('NetworkException', () {
    // NetworkException representa errores de conectividad.
    // Código 0 = error de red no clasificado por HTTP.
    test('should have code 0 for connectivity errors', () {
      final exception = NetworkException('Sin conexión a internet');
      expect(exception.code, 0);
      expect(exception.message, 'Sin conexión a internet');
    });

    test('should be subtype of ApiException', () {
      expect(NetworkException('test'), isA<ApiException>());
    });
  });

  group('ServerException', () {
    // ServerException representa errores 5xx del servidor.
    // Código 500 = error interno del servidor.
    test('should have code 500 for internal server errors', () {
      final exception = ServerException('Error interno del servidor');
      expect(exception.code, 500);
      expect(exception.message, 'Error interno del servidor');
    });

    test('should be subtype of ApiException', () {
      expect(ServerException('test'), isA<ApiException>());
    });
  });

  group('ApiException.fromStatusCode', () {
    // El factory method debe retornar el subtipo correcto
    // según el código HTTP.

    test('should return AuthException for 401', () {
      final exception = ApiException.fromStatusCode(401);
      expect(exception, isA<AuthException>());
      // Verifica que el mensaje por defecto sea descriptivo
      expect(exception.message, contains('No autorizado'));
    });

    test('should return AuthException for 403', () {
      final exception = ApiException.fromStatusCode(403);
      expect(exception, isA<AuthException>());
      // 403 es "prohibido" (autorización), no "no autenticado"
      expect(exception.message, contains('Acceso denegado'));
    });

    test('should return ServerException for 500', () {
      final exception = ApiException.fromStatusCode(500);
      expect(exception, isA<ServerException>());
      expect(exception.message, contains('Error interno'));
    });

    test('should return ServerException for 502', () {
      final exception = ApiException.fromStatusCode(502);
      expect(exception, isA<ServerException>());
    });

    test('should return ServerException for 503', () {
      final exception = ApiException.fromStatusCode(503);
      expect(exception, isA<ServerException>());
    });

    // Códigos no mapeados explícitamente deben retornar
    // una ApiException genérica con ese código conservado.
    test('should return generic ApiException for unknown status codes', () {
      final exception = ApiException.fromStatusCode(418);
      // Verifica que sea ApiException pero NO un subtipo específico
      expect(exception, isA<ApiException>());
      expect(exception, isNot(isA<AuthException>()));
      expect(exception.code, 418);
      expect(exception.message, contains('Error'));
    });

    // Errores de red (códigos negativos o 0) deben retornar NetworkException
    test('should return NetworkException for code 0', () {
      final exception = ApiException.fromStatusCode(0);
      expect(exception, isA<NetworkException>());
    });
  });
}
