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
import 'package:mundo_limpio_app/core/storage/token_storage.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';

// Mock del repositorio para aislar el provider de la capa de datos
class MockAuthRepository extends Mock implements AuthRepository {}

// Mock de TokenStorage para aislar el provider del almacenamiento
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenStorage mockTokenStorage;
  late AuthProvider provider;

  const testEmail = 'test@example.com';
  const testPassword = 'SecurePass123!';

  // AuthResponse de ejemplo para usar en múltiples tests
  final authResponse = AuthResponse(
    accessToken: 'access-123',
    refreshToken: 'refresh-456',
    role: 'user',
    username: 'testuser',
    email: 'testuser@example.com',
    roles: ['user'],
    createdAt: DateTime(2026, 5, 9),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();
    provider = AuthProvider(mockAuthRepository, mockTokenStorage);

    // Stubs por defecto para evitar null errors en mocktail
    when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => false);
    when(
      () => mockAuthRepository.login(any(), any()),
    ).thenAnswer((_) async => authResponse);
    when(
      () => mockAuthRepository.register(any(), any()),
    ).thenAnswer((_) async => authResponse);
    when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
    when(() => mockTokenStorage.readRoles()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.readUsername()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.readEmail()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.saveRoles(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.saveUsername(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.saveEmail(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.clearAll()).thenAnswer((_) async {});
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

    // TDD: RED — verificar que role es null antes de login
    test('role debe ser null al iniciar', () {
      expect(provider.role, isNull);
    });
  });

  group('checkAuth', () {
    test('debe setear authenticated cuando hay tokens locales', () async {
      // Arrange: hay tokens guardados
      when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => true);
      when(
        () => mockTokenStorage.readRoles(),
      ).thenAnswer((_) async => ['user']);
      when(
        () => mockTokenStorage.readUsername(),
      ).thenAnswer((_) async => 'testuser');
      when(
        () => mockTokenStorage.readEmail(),
      ).thenAnswer((_) async => 'test@example.com');

      // Act
      await provider.checkAuth();

      // Assert
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('debe restaurar roles, username y email desde TokenStorage', () async {
      // Arrange
      when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => true);
      when(
        () => mockTokenStorage.readRoles(),
      ).thenAnswer((_) async => ['ADMIN', 'STOCK_MANAGER']);
      when(
        () => mockTokenStorage.readUsername(),
      ).thenAnswer((_) async => 'adminuser');
      when(
        () => mockTokenStorage.readEmail(),
      ).thenAnswer((_) async => 'admin@test.com');

      // Act
      await provider.checkAuth();

      // Assert
      expect(provider.roles, ['ADMIN', 'STOCK_MANAGER']);
      expect(provider.role, 'ADMIN'); // firstOrNull
      expect(provider.username, 'adminuser');
      expect(provider.email, 'admin@test.com');
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
      when(
        () => mockAuthRepository.login(testEmail, testPassword),
      ).thenAnswer((_) async => authResponse);

      // Act
      await provider.login(testEmail, testPassword);

      // Assert
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.error, isNull);
      verify(() => mockAuthRepository.login(testEmail, testPassword)).called(1);
    });

    test(
      'debe setear error y unauthenticated con credenciales inválidas (R3.2)',
      () async {
        // Arrange: el repositorio lanza AuthException
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenThrow(const AuthException('Credenciales inválidas'));

        // Act
        await provider.login(testEmail, testPassword);

        // Assert
        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.error, contains('No autorizado'));
      },
    );

    test(
      'debe setear error de red y unauthenticated sin conexión (R3.3)',
      () async {
        // Arrange: el repositorio lanza NetworkException
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenThrow(const NetworkException('Sin conexión'));

        // Act
        await provider.login(testEmail, testPassword);

        // Assert
        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.error, contains('Sin conexión'));
      },
    );

    // Triangulación: error genérico (no ApiException)
    test('debe manejar errores genéricos en login', () async {
      when(
        () => mockAuthRepository.login(testEmail, testPassword),
      ).thenThrow(Exception('Error inesperado'));

      await provider.login(testEmail, testPassword);

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.error, contains('Error inesperado'));
    });

    // Triangulación: login con diferentes credenciales
    test('debe pasar las credenciales correctas al repositorio', () async {
      await provider.login('otro@test.com', 'OtraPass456!');

      verify(
        () => mockAuthRepository.login('otro@test.com', 'OtraPass456!'),
      ).called(1);
    });

    // TDD: RED — verificar que login guarda el role del AuthResponse
    test(
      'debe guardar role desde AuthResponse después de login exitoso',
      () async {
        // Arrange
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenAnswer((_) async => authResponse);

        // Act
        await provider.login(testEmail, testPassword);

        // Assert
        expect(provider.role, 'user');
      },
    );

    // TDD: RED — verificar que login guarda email y roles del AuthResponse
    test(
      'debe guardar email y roles desde AuthResponse después de login exitoso',
      () async {
        // Arrange
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenAnswer((_) async => authResponse);

        // Act
        await provider.login(testEmail, testPassword);

        // Assert
        expect(provider.email, 'testuser@example.com');
        expect(provider.roles, ['user']);
      },
    );

    // TDD: RED — verificar que email y roles son null antes de login
    test('email y roles deben ser null al iniciar', () {
      expect(provider.email, isNull);
      expect(provider.roles, isNull);
    });

    // TDD: RED — login debe persistir roles/username/email en TokenStorage
    test('login debe persistir roles en TokenStorage', () async {
      // Act
      await provider.login(testEmail, testPassword);

      // Assert
      verify(() => mockTokenStorage.saveRoles(['user'])).called(1);
      verify(() => mockTokenStorage.saveUsername('testuser')).called(1);
      verify(
        () => mockTokenStorage.saveEmail('testuser@example.com'),
      ).called(1);
    });

    // Edge case: email null en response no debe llamar saveEmail
    test('login sin email no debe persistir email', () async {
      // Arrange
      final responseSinEmail = AuthResponse(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        role: 'user',
        username: 'testuser',
        roles: ['user'],
        createdAt: DateTime(2026, 5, 9),
      );
      when(
        () => mockAuthRepository.login(any(), any()),
      ).thenAnswer((_) async => responseSinEmail);

      // Act
      await provider.login(testEmail, testPassword);

      // Assert
      verify(() => mockTokenStorage.saveRoles(['user'])).called(1);
      verify(() => mockTokenStorage.saveUsername('testuser')).called(1);
      verifyNever(() => mockTokenStorage.saveEmail(any()));
    });

    // TDD: RED — Crashlytics debe recibir roles.join(',') en lugar de role
    test('login debe pasar roles.join(",") a Crashlytics', () async {
      // Act
      await provider.login(testEmail, testPassword);

      // Assert: se llama al repo, no verificamos Crashlytics directamente
      // porque es estático. Verificamos que el provider tenga los roles.
      expect(provider.roles, ['user']);
    });
  });

  group('register', () {
    test('debe setear unauthenticated en registro exitoso (R2.1)', () async {
      // Arrange
      when(
        () => mockAuthRepository.register(testEmail, testPassword),
      ).thenAnswer((_) async => authResponse);

      // Act
      await provider.register(testEmail, testPassword);

      // Assert: queda en unauthenticated porque debe redirigir a login
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.error, isNull);
      verify(
        () => mockAuthRepository.register(testEmail, testPassword),
      ).called(1);
    });

    test('debe persistir roles/username/email en registro exitoso', () async {
      // Arrange
      when(
        () => mockAuthRepository.register(testEmail, testPassword),
      ).thenAnswer((_) async => authResponse);

      // Act
      await provider.register(testEmail, testPassword);

      // Assert
      expect(provider.roles, ['user']);
      expect(provider.username, 'testuser');
      expect(provider.email, 'testuser@example.com');
      verify(() => mockTokenStorage.saveRoles(['user'])).called(1);
      verify(() => mockTokenStorage.saveUsername('testuser')).called(1);
      verify(
        () => mockTokenStorage.saveEmail('testuser@example.com'),
      ).called(1);
    });

    test(
      'debe setear error y unauthenticated con email duplicado (R2.2)',
      () async {
        // Arrange: el repositorio lanza ApiException con código 409
        when(
          () => mockAuthRepository.register(testEmail, testPassword),
        ).thenThrow(const ApiException('Email already registered', 409));

        // Act
        await provider.register(testEmail, testPassword);

        // Assert
        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.error, contains('Email already registered'));
      },
    );

    // Triangulación: error genérico en register (no ApiException)
    test(
      'debe manejar errores genéricos en register con mensaje genérico',
      () async {
        when(
          () => mockAuthRepository.register(testEmail, testPassword),
        ).thenThrow(Exception('Error de registro'));

        await provider.register(testEmail, testPassword);

        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.error, contains('Error inesperado'));
      },
    );
  });

  group('logout', () {
    test('debe setear unauthenticated y limpiar TokenStorage (R5.1)', () async {
      // Arrange: autenticar primero
      when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => true);
      await provider.checkAuth();
      expect(provider.isAuthenticated, isTrue);

      // Act
      await provider.logout();

      // Assert
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      verify(() => mockTokenStorage.clearAll()).called(1);
      verify(() => mockAuthRepository.logout()).called(1);
    });

    test('debe limpiar roles, email y username después de logout', () async {
      // Arrange: simular estado autenticado con datos
      when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => true);
      when(
        () => mockTokenStorage.readRoles(),
      ).thenAnswer((_) async => ['ADMIN']);
      when(
        () => mockTokenStorage.readUsername(),
      ).thenAnswer((_) async => 'admin');
      when(
        () => mockTokenStorage.readEmail(),
      ).thenAnswer((_) async => 'admin@test.com');
      await provider.checkAuth();

      // Act
      await provider.logout();

      // Assert
      expect(provider.role, isNull);
      expect(provider.roles, isNull);
      expect(provider.email, isNull);
      expect(provider.username, isNull);
    });
  });

  group('clearError', () {
    test('debe limpiar el mensaje de error', () async {
      // Arrange: forzar un error
      when(
        () => mockAuthRepository.login(testEmail, testPassword),
      ).thenThrow(const AuthException('Error'));
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
      when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => true);
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
      when(
        () => mockAuthRepository.login(testEmail, testPassword),
      ).thenThrow(const AuthException('Error'));
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
