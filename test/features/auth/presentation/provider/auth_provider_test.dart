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

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/storage/token_storage.dart';
import 'package:mundo_limpio_app/features/auth/domain/entities/auth_session.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/core/crashlytics/crashlytics_service.dart';

// Mock del repositorio para aislar el provider de la capa de datos
class MockAuthRepository extends Mock implements AuthRepository {}

// Mock de TokenStorage para aislar el provider del almacenamiento
class MockTokenStorage extends Mock implements TokenStorage {}

// Mock de FirebaseCrashlytics para verificar logging
class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenStorage mockTokenStorage;
  late MockFirebaseCrashlytics mockCrashlytics;
  late AuthProvider provider;

  const testEmail = 'test@example.com';
  const testPassword = 'SecurePass123!';

  // AuthSession de ejemplo para usar en múltiples tests
  final authSession = AuthSession(
    userId: 0,
    username: 'testuser',
    email: 'testuser@example.com',
    roles: ['user'],
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();
    mockCrashlytics = MockFirebaseCrashlytics();
    provider = AuthProvider(mockAuthRepository, mockTokenStorage);

    // Inyectar mock de Crashlytics
    CrashlyticsService.testInstance = mockCrashlytics;
    CrashlyticsService.setOptOut(false);

    // Stub void para recordError
    when(
      () =>
          mockCrashlytics.recordError(any(), any(), fatal: any(named: 'fatal')),
    ).thenAnswer((_) async {});

    // Stubs por defecto para evitar null errors en mocktail
    when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => false);
    when(
      () => mockAuthRepository.login(any(), any()),
    ).thenAnswer((_) async => authSession);
    when(
      () => mockAuthRepository.register(any(), any()),
    ).thenAnswer((_) async => authSession);
    when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
    when(() => mockTokenStorage.readRoles()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.readUsername()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.readEmail()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.saveRoles(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.saveUsername(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.saveEmail(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.clearAll()).thenAnswer((_) async {});
  });

  tearDown(() {
    CrashlyticsService.resetForTesting();
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

    test('role debe ser null al iniciar', () {
      expect(provider.role, isNull);
    });
  });

  group('checkAuth', () {
    test('debe setear authenticated cuando hay tokens locales', () async {
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

      await provider.checkAuth();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('debe restaurar roles, username y email desde TokenStorage', () async {
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

      await provider.checkAuth();

      expect(provider.roles, ['ADMIN', 'STOCK_MANAGER']);
      expect(provider.role, 'ADMIN');
      expect(provider.username, 'adminuser');
      expect(provider.email, 'admin@test.com');
    });

    test('debe setear unauthenticated cuando NO hay tokens locales', () async {
      await provider.checkAuth();

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
      when(
        () => mockAuthRepository.login(testEmail, testPassword),
      ).thenAnswer((_) async => authSession);

      await provider.login(testEmail, testPassword);

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.error, isNull);
      verify(() => mockAuthRepository.login(testEmail, testPassword)).called(1);
    });

    test(
      'debe setear error y unauthenticated con credenciales inválidas (R3.2)',
      () async {
        when(() => mockAuthRepository.login(testEmail, testPassword)).thenThrow(
          const AuthException('No autorizado. Iniciá sesión nuevamente.'),
        );

        await provider.login(testEmail, testPassword);

        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.error, contains('No autorizado'));
      },
    );

    test(
      'debe setear error de red y unauthenticated sin conexión (R3.3)',
      () async {
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenThrow(const NetworkException('Sin conexión'));

        await provider.login(testEmail, testPassword);

        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.error, contains('Sin conexión'));
      },
    );

    // R4.1: ApiException NO debe llamar Crashlytics.recordError
    test(
      'R4.1: ApiException en login NO debe llamar Crashlytics.recordError',
      () async {
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenThrow(const ValidationException('Contraseña muy débil'));

        await provider.login(testEmail, testPassword);

        // El on ApiException catch maneja el error, el generic catch no se ejecuta
        verifyNever(
          () => mockCrashlytics.recordError(
            any(),
            any(),
            fatal: any(named: 'fatal'),
          ),
        );
        expect(provider.status, AuthStatus.unauthenticated);
      },
    );

    // Triangulación: error genérico (no ApiException) debe loggearse
    test(
      'debe llamar Crashlytics.recordError para errores genéricos en login',
      () async {
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenThrow(Exception('Error inesperado'));

        await provider.login(testEmail, testPassword);

        verify(
          () => mockCrashlytics.recordError(
            any(),
            any(),
            fatal: any(named: 'fatal'),
          ),
        ).called(1);
        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.error, contains('Error inesperado'));
      },
    );

    test('debe pasar las credenciales correctas al repositorio', () async {
      await provider.login('otro@test.com', 'OtraPass456!');

      verify(
        () => mockAuthRepository.login('otro@test.com', 'OtraPass456!'),
      ).called(1);
    });

    test(
      'debe guardar role desde AuthResponse después de login exitoso',
      () async {
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenAnswer((_) async => authSession);

        await provider.login(testEmail, testPassword);

        expect(provider.role, 'user');
      },
    );

    test(
      'debe guardar email y roles desde AuthResponse después de login exitoso',
      () async {
        when(
          () => mockAuthRepository.login(testEmail, testPassword),
        ).thenAnswer((_) async => authSession);

        await provider.login(testEmail, testPassword);

        expect(provider.email, 'testuser@example.com');
        expect(provider.roles, ['user']);
      },
    );

    test('email y roles deben ser null al iniciar', () {
      expect(provider.email, isNull);
      expect(provider.roles, isNull);
    });

    test('login debe persistir roles en TokenStorage', () async {
      await provider.login(testEmail, testPassword);

      verify(() => mockTokenStorage.saveRoles(['user'])).called(1);
      verify(() => mockTokenStorage.saveUsername('testuser')).called(1);
      verify(
        () => mockTokenStorage.saveEmail('testuser@example.com'),
      ).called(1);
    });

    test('login sin email no debe persistir email', () async {
      final responseSinEmail = AuthSession(
        userId: 0,
        username: 'testuser',
        roles: ['user'],
      );
      when(
        () => mockAuthRepository.login(any(), any()),
      ).thenAnswer((_) async => responseSinEmail);

      await provider.login(testEmail, testPassword);

      verify(() => mockTokenStorage.saveRoles(['user'])).called(1);
      verify(() => mockTokenStorage.saveUsername('testuser')).called(1);
      verifyNever(() => mockTokenStorage.saveEmail(any()));
    });

    test('login debe pasar roles.join(",") a Crashlytics', () async {
      await provider.login(testEmail, testPassword);

      expect(provider.roles, ['user']);
    });
  });

  group('register', () {
    test('debe setear unauthenticated en registro exitoso (R2.1)', () async {
      when(
        () => mockAuthRepository.register(testEmail, testPassword),
      ).thenAnswer((_) async => authSession);

      await provider.register(testEmail, testPassword);

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.error, isNull);
      verify(
        () => mockAuthRepository.register(testEmail, testPassword),
      ).called(1);
    });

    test('debe persistir roles/username/email en registro exitoso', () async {
      when(
        () => mockAuthRepository.register(testEmail, testPassword),
      ).thenAnswer((_) async => authSession);

      await provider.register(testEmail, testPassword);

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
        when(
          () => mockAuthRepository.register(testEmail, testPassword),
        ).thenThrow(const UnknownApiException('Email already registered', 409));

        await provider.register(testEmail, testPassword);

        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.error, contains('Email already registered'));
      },
    );

    // R4.2: Error genérico en register debe loggearse a Crashlytics
    test(
      'R4.2: debe llamar Crashlytics.recordError para errores genéricos en register',
      () async {
        when(
          () => mockAuthRepository.register(testEmail, testPassword),
        ).thenThrow(FormatException('Error de registro'));

        await provider.register(testEmail, testPassword);

        verify(
          () => mockCrashlytics.recordError(
            any(),
            any(),
            fatal: any(named: 'fatal'),
          ),
        ).called(1);
        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.error, contains('Error inesperado'));
      },
    );

    // R4.1: ApiException en register NO debe llamar Crashlytics.recordError
    test(
      'R4.1: ApiException en register NO debe llamar Crashlytics.recordError',
      () async {
        when(
          () => mockAuthRepository.register(testEmail, testPassword),
        ).thenThrow(const ConflictException('El email ya está registrado'));

        await provider.register(testEmail, testPassword);

        verifyNever(
          () => mockCrashlytics.recordError(
            any(),
            any(),
            fatal: any(named: 'fatal'),
          ),
        );
        expect(provider.status, AuthStatus.unauthenticated);
      },
    );
  });

  group('logout', () {
    test('debe setear unauthenticated y limpiar TokenStorage (R5.1)', () async {
      when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => true);
      await provider.checkAuth();
      expect(provider.isAuthenticated, isTrue);

      await provider.logout();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.isAuthenticated, isFalse);
      verify(() => mockTokenStorage.clearAll()).called(1);
      verify(() => mockAuthRepository.logout()).called(1);
    });

    test('debe limpiar roles, email y username después de logout', () async {
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

      await provider.logout();

      expect(provider.role, isNull);
      expect(provider.roles, isNull);
      expect(provider.email, isNull);
      expect(provider.username, isNull);
    });
  });

  group('clearError', () {
    test('debe limpiar el mensaje de error', () async {
      when(
        () => mockAuthRepository.login(testEmail, testPassword),
      ).thenThrow(const AuthException('Error'));
      await provider.login(testEmail, testPassword);
      expect(provider.error, isNotNull);

      provider.clearError();

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

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante login', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.login(testEmail, testPassword);

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante logout', () async {
      when(() => mockAuthRepository.isLoggedIn()).thenAnswer((_) async => true);
      await provider.checkAuth();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.logout();

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners en clearError', () async {
      when(
        () => mockAuthRepository.login(testEmail, testPassword),
      ).thenThrow(const AuthException('Error'));
      await provider.login(testEmail, testPassword);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();

      expect(notifyCount, greaterThan(0));
    });
  });
}
