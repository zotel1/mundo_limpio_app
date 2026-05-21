// Pruebas unitarias para SplashRepositoryImpl.
//
// Verifica que el repositorio llama a Dio GET /actuator/health
// y maneja correctamente los tres escenarios:
// - Éxito: HTTP 200 → retorna true
// - Error de red: DioException → retorna false (NO lanza)
// - Timeout: connectionTimeout → retorna false (NO lanza)
//
// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/splash/data/splash_repository_impl.dart';

// Mock de Dio para aislar el repositorio de la red real
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SplashRepositoryImpl repository;

  setUp(() {
    mockDio = MockDio();
    repository = SplashRepositoryImpl(dio: mockDio);
  });

  group('wakeBackend — éxito', () {
    test('debe retornar true cuando el backend responde HTTP 200', () async {
      // Arrange: simular respuesta exitosa del backend
      final response = Response(
        requestOptions: RequestOptions(path: '/actuator/health'),
        statusCode: 200,
        data: {'status': 'UP'},
      );
      when(
        () => mockDio.get('/actuator/health'),
      ).thenAnswer((_) async => response);

      // Act
      final result = await repository.wakeBackend();

      // Assert
      expect(result, isTrue);
      verify(() => mockDio.get('/actuator/health')).called(1);
    });

    test(
      'debe retornar false cuando el backend responde código != 200',
      () async {
        // Arrange: simular respuesta con error del servidor
        final errorResponse = Response(
          requestOptions: RequestOptions(path: '/actuator/health'),
          statusCode: 503,
        );
        when(
          () => mockDio.get('/actuator/health'),
        ).thenAnswer((_) async => errorResponse);

        // Act
        final result = await repository.wakeBackend();

        // Assert
        expect(result, isFalse);
      },
    );
  });

  group('wakeBackend — error', () {
    test(
      'debe retornar false cuando Dio lanza una excepción (sin lanzar)',
      () async {
        // Arrange: simular error de red
        when(() => mockDio.get('/actuator/health')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/actuator/health'),
            message: 'Connection refused',
          ),
        );

        // Act: NO debe lanzar — el repositorio captura y retorna false
        final result = await repository.wakeBackend();

        // Assert
        expect(result, isFalse);
      },
    );

    test(
      'debe retornar false cuando ocurre timeout de conexión (sin lanzar)',
      () async {
        // Arrange: simular timeout
        when(() => mockDio.get('/actuator/health')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/actuator/health'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act
        final result = await repository.wakeBackend();

        // Assert
        expect(result, isFalse);
      },
    );

    test(
      'debe retornar false cuando ocurre timeout de recepción (sin lanzar)',
      () async {
        // Arrange: simular receive timeout
        when(() => mockDio.get('/actuator/health')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/actuator/health'),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        // Act
        final result = await repository.wakeBackend();

        // Assert
        expect(result, isFalse);
      },
    );
  });
}
