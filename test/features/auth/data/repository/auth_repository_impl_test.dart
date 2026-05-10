// Pruebas unitarias para AuthRepositoryImpl.
// Verifica que el repositorio coordina correctamente AuthApi y TokenStorage:
// - login: llama AuthApi → guarda tokens → retorna AuthResponse
// - register: llama AuthApi → retorna AuthResponse
// - logout: limpia tokens
// - refreshToken: llama AuthApi → guarda nuevos tokens → retorna AuthResponse
// - isLoggedIn: delega en TokenStorage.hasTokens
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/core/storage/token_storage.dart';
import 'package:mundo_limpio_app/features/auth/data/api/auth_api.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';
import 'package:mundo_limpio_app/features/auth/data/repository/auth_repository_impl.dart';

// Mocks para las dependencias del repositorio
class MockAuthApi extends Mock implements AuthApi {}
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthApi mockAuthApi;
  late MockTokenStorage mockTokenStorage;
  late AuthRepositoryImpl repository;

  // AuthResponse de ejemplo para usar en múltiples tests
  final authResponse = AuthResponse(
    accessToken: 'access-123',
    refreshToken: 'refresh-456',
    role: 'user',
    username: 'testuser',
    createdAt: DateTime(2026, 5, 9),
  );

  const testEmail = 'test@example.com';
  const testPassword = 'SecurePass123!';

  setUp(() {
    mockAuthApi = MockAuthApi();
    mockTokenStorage = MockTokenStorage();
    repository = AuthRepositoryImpl(
      authApi: mockAuthApi,
      tokenStorage: mockTokenStorage,
    );

    // Stubs por defecto para evitar UnexpectedNullError en mocktail
    when(() => mockTokenStorage.saveTokens(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockTokenStorage.clear())
        .thenAnswer((_) async {});
    when(() => mockTokenStorage.hasTokens())
        .thenAnswer((_) async => false);
  });

  group('login', () {
    // Verifica que login llama a AuthApi.login y guarda tokens
    test('debe llamar AuthApi.login y guardar tokens en login exitoso', () async {
      // Arrange
      when(() => mockAuthApi.login(testEmail, testPassword))
          .thenAnswer((_) async => authResponse);

      // Act
      final result = await repository.login(testEmail, testPassword);

      // Assert: retorna el AuthResponse correcto
      expect(result.accessToken, 'access-123');
      expect(result.refreshToken, 'refresh-456');

      // Assert: guarda ambos tokens en storage
      verify(() => mockTokenStorage.saveTokens('access-123', 'refresh-456')).called(1);
    });

    // Triangulación: login con diferentes credenciales
    test('debe pasar las credenciales correctas a AuthApi.login', () async {
      when(() => mockAuthApi.login('other@test.com', 'OtherPass456!'))
          .thenAnswer((_) async => authResponse);

      await repository.login('other@test.com', 'OtherPass456!');

      verify(() => mockAuthApi.login('other@test.com', 'OtherPass456!')).called(1);
    });
  });

  group('register', () {
    // Verifica que register llama a AuthApi.register y retorna el AuthResponse
    test('debe llamar AuthApi.register y retornar AuthResponse (R2.1)', () async {
      // Arrange
      when(() => mockAuthApi.register(testEmail, testPassword))
          .thenAnswer((_) async => authResponse);

      // Act
      final result = await repository.register(testEmail, testPassword);

      // Assert
      expect(result.accessToken, 'access-123');
      expect(result.username, 'testuser');
      verify(() => mockAuthApi.register(testEmail, testPassword)).called(1);
    });

    // Triangulación: register no debe guardar tokens
    test('NO debe guardar tokens después de register', () async {
      when(() => mockAuthApi.register(testEmail, testPassword))
          .thenAnswer((_) async => authResponse);

      await repository.register(testEmail, testPassword);

      verifyNever(() => mockTokenStorage.saveTokens(any(), any()));
    });
  });

  group('logout', () {
    // Verifica que logout limpia todos los tokens (R5.1)
    test('debe llamar TokenStorage.clear en logout (R5.1)', () async {
      await repository.logout();

      verify(() => mockTokenStorage.clear()).called(1);
    });
  });

  group('refreshToken', () {
    // Verifica que refreshToken llama AuthApi.refresh y guarda nuevos tokens
    test('debe refrescar tokens y guardarlos (R4.1)', () async {
      // Arrange
      const refreshToken = 'old-refresh-token';
      final newResponse = AuthResponse(
        accessToken: 'new-access-789',
        refreshToken: 'new-refresh-012',
        role: 'user',
        username: 'testuser',
        createdAt: DateTime(2026, 5, 9),
      );
      when(() => mockAuthApi.refresh(refreshToken))
          .thenAnswer((_) async => newResponse);

      // Act
      final result = await repository.refreshToken(refreshToken);

      // Assert: guarda los NUEVOS tokens
      expect(result.accessToken, 'new-access-789');
      verify(() => mockTokenStorage.saveTokens('new-access-789', 'new-refresh-012')).called(1);
    });
  });

  group('isLoggedIn', () {
    // Verifica que isLoggedIn delega en TokenStorage.hasTokens
    test('debe retornar true cuando hay tokens (R1.1)', () async {
      when(() => mockTokenStorage.hasTokens())
          .thenAnswer((_) async => true);

      final result = await repository.isLoggedIn();

      expect(result, isTrue);
    });

    // Verifica que retorna false cuando no hay tokens (R1.2)
    test('debe retornar false cuando no hay tokens', () async {
      final result = await repository.isLoggedIn();

      expect(result, isFalse);
    });
  });
}
