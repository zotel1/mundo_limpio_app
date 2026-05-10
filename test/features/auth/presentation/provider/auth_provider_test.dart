// Pruebas unitarias para AuthProvider.
//
// Verifica el ciclo de vida del estado de autenticación:
// - login exitoso → authenticated (R3.1)
// - login fallido (credenciales inválidas) → error + unauthenticated (R3.2)
// - login fallido (red) → error de red + unauthenticated (R3.3)
// - registro exitoso → unauthenticated (R2.1)
// - registro fallido (email duplicado) → error (R2.2)
// - logout → unauthenticated (R5.1)
// - checkAuth → authenticated/unauthenticated según tokens locales
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';

// Mock del repositorio para aislar el provider de la capa de datos
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthProvider provider;

  const testEmail = 'test@example.com';
  const testPassword = 'SecurePass123!';

  // AuthResponse de ejemplo para usar en múltiples tests
  final authResponse = AuthResponse(
    accessToken: 'access-123',
    refreshToken: 'refresh-456',
    role: 'user',
    username: 'testuser',
    createdAt: DateTime(2026, 5, 9),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    provider = AuthProvider(mockAuthRepository);

    // Stubs por defecto para evitar null errors en mocktail
    when(() => mockAuthRepository.isLoggedIn())
        .thenAnswer((_) async => false);
    when(() => mockAuthRepository.login(any(), any()))
        .thenAnswer((_) async => authResponse);
    when(() => mockAuthRepository.register(any(), any()))
        .thenAnswer((_) async => authResponse);
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async {});
  });

  group('estado inicial', () {
    test('debe iniciar con status loading', () {
      expect(provider.status, AuthStatus.loading);
    });

    test('debe iniciar sin error', () {
      expect(provider.error, isNull);
    });

    test('isLoading debe ser true al iniciar', () {
      expect(provider.isLoading, isTrue);
    });

    test('isAuthenticated debe ser false al iniciar', () {
      expect(provider.isAuthenticated, isFalse);
    });
  });

  group('checkAuth', () {
    test('debe setear authenticated cuando hay tokens locales', () async {
      // Arrange: hay tokens guardados
      when(() => mockAuthRepository.isLoggedIn())
          .thenAnswer((_) async => true);

      // Act
      await provider.checkAuth();

      // Assert
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('debe setear unauthenticated cuando NO hay tokens locales', () async {
      // Arrange: no hay tokens (default stub ya retorna false)

      // Act
      await provider.checkAuth();

      // Assert
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('debe llamar isLoggedIn del repositorio', () async {
      await provider.checkAuth();

      verify(() => mockAuthRepository.isLoggedIn()).called(1);
    });
  });

  group('login', () {
    test('debe setear authenticated en login exitoso (R3.1)', () async {
      // Arrange
      when(() => mockAuthRepository.login(testEmail, testPassword))
          .thenAnswer((_) async => authResponse);

      // Act
      await provider.login(testEmail, testPassword);

      // Assert
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.error, isNull);
      verify(() => mockAuthRepository.login(testEmail, testPassword)).called(1);
    });

    test('debe setear error y unauthenticated con credenciales inválidas (R3.2)', () async {
      // Arrange: el repositorio lanza AuthException
      when(() => mockAuthRepository.login(testEmail, testPassword))
          .thenThrow(const AuthException('Credenciales inválidas'));

      // Act
      await provider.login(testEmail, testPassword);

      // Assert
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.error, contains('No autorizado'));
    });

    test('debe setear error de red y unauthenticated sin conexión (R3.3)', () async {
      // Arrange: el repositorio lanza NetworkException
      when(() => mockAuthRepository.login(testEmail, testPassword))
          .thenThrow(const NetworkException('Sin conexión'));

      // Act
      await provider.login(testEmail, testPassword);

      // Assert
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.error, contains('Sin conexión'));
    });

    // Triangulación: error genérico (no ApiException)
    test('debe manejar errores genéricos en login', () async {
      when(() => mockAuthRepository.login(testEmail, testPassword))
          .thenThrow(Exception('Error inesperado'));

      await provider.login(testEmail, testPassword);

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.error, contains('Error inesperado'));
    });

    // Triangulación: login con diferentes credenciales
    test('debe pasar las credenciales correctas al repositorio', () async {
      await provider.login('otro@test.com', 'OtraPass456!');

      verify(() => mockAuthRepository.login('otro@test.com', 'OtraPass456!')).called(1);
    });
  });

  group('register', () {
    test('debe setear unauthenticated en registro exitoso (R2.1)', () async {
      // Arrange
      when(() => mockAuthRepository.register(testEmail, testPassword))
          .thenAnswer((_) async => authResponse);

      // Act
      await provider.register(testEmail, testPassword);

      // Assert: queda en unauthenticated porque debe redirigir a login
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.error, isNull);
      verify(() => mockAuthRepository.register(testEmail, testPassword)).called(1);
    });

    test('debe setear error y unauthenticated con email duplicado (R2.2)', () async {
      // Arrange: el repositorio lanza ApiException con código 409
      when(() => mockAuthRepository.register(testEmail, testPassword))
          .thenThrow(const ApiException('Email already registered', 409));

      // Act
      await provider.register(testEmail, testPassword);

      // Assert
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.error, contains('Email already registered'));
    });

    // Triangulación: error genérico en register (no ApiException)
    test('debe manejar errores genéricos en register con mensaje genérico', () async {
      when(() => mockAuthRepository.register(testEmail, testPassword))
          .thenThrow(Exception('Error de registro'));

      await provider.register(testEmail, testPassword);

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.error, contains('Error inesperado'));
    });
  });

  group('logout', () {
    test('debe setear unauthenticated y llamar repo.logout (R5.1)', () async {
      // Arrange: autenticar primero
      when(() => mockAuthRepository.isLoggedIn())
          .thenAnswer((_) async => true);
      await provider.checkAuth();
      expect(provider.isAuthenticated, isTrue);

      // Act
      await provider.logout();

      // Assert
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      verify(() => mockAuthRepository.logout()).called(1);
    });
  });

  group('clearError', () {
    test('debe limpiar el mensaje de error', () async {
      // Arrange: forzar un error
      when(() => mockAuthRepository.login(testEmail, testPassword))
          .thenThrow(const AuthException('Error'));
      await provider.login(testEmail, testPassword);
      expect(provider.error, isNotNull);

      // Act
      provider.clearError();

      // Assert
      expect(provider.error, isNull);
    });
  });

  group('ChangeNotifier', () {
    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });

    test('debe llamar notifyListeners durante checkAuth', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.checkAuth();

      // checkAuth cambia estado al menos una vez
      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante login', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.login(testEmail, testPassword);

      // login cambia estado al menos una vez
      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante logout', () async {
      // Arrange: autenticar primero
      when(() => mockAuthRepository.isLoggedIn())
          .thenAnswer((_) async => true);
      await provider.checkAuth();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Act
      await provider.logout();

      // Assert
      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners en clearError', () async {
      // Arrange: poner el provider en estado de error
      when(() => mockAuthRepository.login(testEmail, testPassword))
          .thenThrow(const AuthException('Error'));
      await provider.login(testEmail, testPassword);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Act
      provider.clearError();

      // Assert
      expect(notifyCount, greaterThan(0));
    });
  });
}
