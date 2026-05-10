// Pruebas unitarias para AuthApi.
// Verifica que las llamadas HTTP a login, register y refresh
// se hacen correctamente y que los errores HTTP se convierten
// a ApiException con el subtipo correcto.
//
// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/auth/data/api/auth_api.dart';

// Mock de Dio para aislar las pruebas HTTP de la red real
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AuthApi authApi;

  // Constantes para evitar magic strings
  const testEmail = 'test@example.com';
  const testPassword = 'SecurePass123!';
  const testRefreshToken = 'refresh-token-abc';

  setUp(() {
    mockDio = MockDio();
    authApi = AuthApi(dio: mockDio);
  });

  group('login', () {
    // Escenario feliz: POST /api/v1/auth/login retorna 200 con AuthResponse
    test('debe retornar AuthResponse en login exitoso (R3.1)', () async {
      // Arrange: respuesta simulada del backend
      final responseData = {
        'accessToken': 'access-123',
        'refreshToken': 'refresh-456',
        'role': 'user',
        'username': 'testuser',
        'createdAt': '2026-05-09T00:00:00.000',
      };
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        data: responseData,
        statusCode: 200,
      );

      when(() => mockDio.post(
            '/api/v1/auth/login',
            data: any(named: 'data'),
          )).thenAnswer((_) async => response);

      // Act
      final result = await authApi.login(testEmail, testPassword);

      // Assert: verifica que el AuthResponse tiene los campos correctos
      expect(result.accessToken, 'access-123');
      expect(result.refreshToken, 'refresh-456');
      expect(result.role, 'user');
      expect(result.username, 'testuser');
      expect(result.createdAt, DateTime(2026, 5, 9));

      // Verifica que se llamó al endpoint correcto con email y password
      verify(() => mockDio.post(
            '/api/v1/auth/login',
            data: {
              'email': testEmail,
              'password': testPassword,
            },
          )).called(1);
    });

    // Error 401: debe lanzar AuthException
    test('debe lanzar AuthException en login con credenciales inválidas (R3.2)', () async {
      // Arrange: simula 401 Unauthorized
      when(() => mockDio.post(
            '/api/v1/auth/login',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => authApi.login(testEmail, testPassword),
        throwsA(isA<AuthException>()),
      );
    });

    // Error de red: debe lanzar NetworkException
    test('debe lanzar NetworkException en login sin conexión (R3.3)', () async {
      // Arrange: simula timeout/error de red (sin response)
      when(() => mockDio.post(
            '/api/v1/auth/login',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act & Assert
      expect(
        () => authApi.login(testEmail, testPassword),
        throwsA(isA<NetworkException>()),
      );
    });

    // Error 500: debe lanzar ServerException
    test('debe lanzar ServerException en login con error interno (500)', () async {
      when(() => mockDio.post(
            '/api/v1/auth/login',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => authApi.login(testEmail, testPassword),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('register', () {
    // Escenario feliz: POST /api/v1/auth/register retorna 200 con AuthResponse
    test('debe retornar AuthResponse en registro exitoso (R2.1)', () async {
      final responseData = {
        'accessToken': 'access-reg-123',
        'refreshToken': 'refresh-reg-456',
        'role': 'user',
        'username': 'newuser',
        'createdAt': '2026-05-09T10:00:00.000',
      };
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/register'),
        data: responseData,
        statusCode: 200,
      );

      when(() => mockDio.post(
            '/api/v1/auth/register',
            data: any(named: 'data'),
          )).thenAnswer((_) async => response);

      final result = await authApi.register('new@test.com', 'NewPass123!');

      expect(result.accessToken, 'access-reg-123');
      expect(result.role, 'user');
      expect(result.username, 'newuser');

      verify(() => mockDio.post(
            '/api/v1/auth/register',
            data: {
              'email': 'new@test.com',
              'password': 'NewPass123!',
            },
          )).called(1);
    });

    // Error 409 (Conflict) para email duplicado
    test('debe lanzar ApiException en registro con email duplicado (R2.2)', () async {
      when(() => mockDio.post(
            '/api/v1/auth/register',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/register'),
          response: Response(
            statusCode: 409,
            requestOptions: RequestOptions(path: '/api/v1/auth/register'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => authApi.register('existing@test.com', 'Pass123!'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('refresh', () {
    // Escenario feliz: refresh exitoso retorna nuevos tokens
    test('debe retornar AuthResponse en refresh exitoso (R4.1)', () async {
      final responseData = {
        'accessToken': 'new-access-789',
        'refreshToken': 'new-refresh-012',
        'role': 'user',
        'username': 'refresheduser',
        'createdAt': '2026-05-09T12:00:00.000',
      };
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
        data: responseData,
        statusCode: 200,
      );

      when(() => mockDio.post(
            '/api/v1/auth/refresh',
            data: any(named: 'data'),
          )).thenAnswer((_) async => response);

      final result = await authApi.refresh(testRefreshToken);

      expect(result.accessToken, 'new-access-789');
      expect(result.refreshToken, 'new-refresh-012');

      verify(() => mockDio.post(
            '/api/v1/auth/refresh',
            data: {
              'refreshToken': testRefreshToken,
            },
          )).called(1);
    });

    // Error 401 en refresh: tokens expirados
    test('debe lanzar AuthException en refresh con token expirado (R4.2)', () async {
      when(() => mockDio.post(
            '/api/v1/auth/refresh',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => authApi.refresh('expired-refresh-token'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
