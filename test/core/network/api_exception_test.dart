// Pruebas unitarias para la jerarquía de ApiException.
// Verifica la propagación de mensajes, códigos de error,
// subtipos y el factory method fromStatusCode.
//
// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
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
    test('should have fixed code 401', () {
      final exception = AuthException('Token expirado');
      expect(exception.code, 401);
      expect(exception.message, 'Token expirado');
    });

    test('should be subtype of ApiException', () {
      expect(AuthException('test'), isA<ApiException>());
    });
  });

  group('NetworkException', () {
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
    test('should have code 500 for internal server errors', () {
      final exception = ServerException('Error interno del servidor');
      expect(exception.code, 500);
      expect(exception.message, 'Error interno del servidor');
    });

    test('should be subtype of ApiException', () {
      expect(ServerException('test'), isA<ApiException>());
    });
  });

  group('ValidationException', () {
    test('should have fixed code 400', () {
      final exception = ValidationException('Error de validación');
      expect(exception.code, 400);
      expect(exception.message, 'Error de validación');
    });

    test('should be subtype of ApiException', () {
      expect(ValidationException('test'), isA<ApiException>());
    });
  });

  group('ConflictException', () {
    test('should have fixed code 409', () {
      final exception = ConflictException('Conflicto');
      expect(exception.code, 409);
    });

    test('should be subtype of ApiException', () {
      expect(ConflictException('test'), isA<ApiException>());
    });
  });

  group('RateLimitException', () {
    test('should have fixed code 429', () {
      final exception = RateLimitException('Demasiados intentos');
      expect(exception.code, 429);
    });

    test('should be subtype of ApiException', () {
      expect(RateLimitException('test'), isA<ApiException>());
    });
  });

  group('ApiException.fromStatusCode', () {
    test('should return AuthException for 401', () {
      final exception = ApiException.fromStatusCode(401);
      expect(exception, isA<AuthException>());
      expect(exception.message, contains('No autorizado'));
    });

    test('should return AuthException for 403', () {
      final exception = ApiException.fromStatusCode(403);
      expect(exception, isA<AuthException>());
      expect(exception.message, contains('Acceso denegado'));
    });

    test('should return ValidationException for 400', () {
      final exception = ApiException.fromStatusCode(400);
      expect(exception, isA<ValidationException>());
      expect(exception.message, contains('Error de validación'));
    });

    test('should return ConflictException for 409', () {
      final exception = ApiException.fromStatusCode(409);
      expect(exception, isA<ConflictException>());
      expect(exception.message, contains('Error de conflicto'));
    });

    test('should return RateLimitException for 429', () {
      final exception = ApiException.fromStatusCode(429);
      expect(exception, isA<RateLimitException>());
      expect(exception.message, contains('Demasiados intentos'));
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

    test('should return generic ApiException for unknown status codes', () {
      final exception = ApiException.fromStatusCode(418);
      expect(exception, isA<ApiException>());
      expect(exception, isNot(isA<AuthException>()));
      expect(exception.code, 418);
      expect(exception.message, contains('Error'));
    });

    test('should return NetworkException for code 0', () {
      final exception = ApiException.fromStatusCode(0);
      expect(exception, isA<NetworkException>());
    });
  });

  group('ApiException.fromDioException', () {
    test('R1.1: status 400 with data -> ValidationException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 400,
          requestOptions: RequestOptions(path: '/test'),
          data: {'code': 'VALIDATION_ERROR', 'message': 'Contraseña muy débil'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception, isA<ValidationException>());
      expect(exception.message, 'Contraseña muy débil');
      expect(exception.code, 400);
    });

    test('R1.2: status 409 with data -> ConflictException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 409,
          requestOptions: RequestOptions(path: '/test'),
          data: {
            'code': 'EMAIL_ALREADY_IN_USE',
            'message': 'El email ya está registrado',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception, isA<ConflictException>());
      expect(exception.message, 'El email ya está registrado');
      expect(exception.code, 409);
    });

    test('R1.3: status 429 with data -> RateLimitException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 429,
          requestOptions: RequestOptions(path: '/test'),
          data: {
            'code': 'RATE_LIMIT_EXCEEDED',
            'message': 'Demasiados intentos',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception, isA<RateLimitException>());
      expect(exception.message, 'Demasiados intentos');
      expect(exception.code, 429);
    });

    test(
      'Edge R1.4: status 400 without response data -> fallback to fromStatusCode(400)',
      () {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/test'),
          ),
          type: DioExceptionType.badResponse,
        );

        final exception = ApiException.fromDioException(dioException);

        expect(exception, isA<ValidationException>());
        expect(exception.code, 400);
        // Debe tener el mensaje DEFAULT de fromStatusCode(400), no uno personalizado
        expect(exception.message, contains('Error de validación'));
      },
    );

    test(
      'Edge R1.5: status 409 with malformed data -> fallback to fromStatusCode(409)',
      () {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 409,
            requestOptions: RequestOptions(path: '/test'),
            data: 'raw string body' as dynamic, // no es Map
          ),
          type: DioExceptionType.badResponse,
        );

        final exception = ApiException.fromDioException(dioException);

        expect(exception, isA<ConflictException>());
        expect(exception.code, 409);
        // Debe tener el mensaje DEFAULT de fromStatusCode(409)
        expect(exception.message, contains('Error de conflicto'));
      },
    );

    test('should fallback to fromStatusCode for non-400/409/429 status', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/test'),
          data: {'message': 'Server error'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception, isA<ServerException>());
      expect(exception.code, 500);
    });

    test('should fallback to NetworkException when no response', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception, isA<NetworkException>());
      expect(exception.code, 0);
    });
  });
}
