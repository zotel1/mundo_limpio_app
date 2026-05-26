// Prueba de compilación para AuthRepository (abstract).
// Verifica que el contrato abstracto puede ser implementado
// por una clase concreta — garantiza que la interfaz es
// correcta y completa.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';

// Implementación concreta de prueba para verificar que
// el contrato abstracto de AuthRepository es correcto.
class TestAuthRepository implements AuthRepository {
  @override
  Future<AuthResponse> login(String email, String password) async {
    return AuthResponse(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      role: 'user',
      username: 'test',
      roles: ['user'],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<AuthResponse> register(String email, String password) async {
    return AuthResponse(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      role: 'user',
      username: 'test',
      roles: ['user'],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> logout() async {
    // No-op para test
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    return AuthResponse(
      accessToken: 'refreshed-access',
      refreshToken: 'refreshed-refresh',
      role: 'user',
      username: 'test',
      roles: ['user'],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<bool> isLoggedIn() async {
    return true;
  }
}

void main() {
  group('AuthRepository (contrato abstracto)', () {
    // Verifica que la interfaz puede ser implementada (compile-time check)
    test('AuthRepository debe ser implementable', () {
      final repo = TestAuthRepository();
      expect(repo, isA<AuthRepository>());
    });

    // Verifica que los métodos retornan los tipos correctos
    test('login debe retornar AuthResponse', () async {
      final repo = TestAuthRepository();
      final result = await repo.login('a@b.com', 'pass');

      expect(result, isA<AuthResponse>());
      expect(result.accessToken, 'test-access');
    });

    test('register debe retornar AuthResponse', () async {
      final repo = TestAuthRepository();
      final result = await repo.register('a@b.com', 'pass');

      expect(result, isA<AuthResponse>());
    });

    test('logout no debe lanzar excepción', () async {
      final repo = TestAuthRepository();
      await repo.logout(); // No debe lanzar
    });

    test('refreshToken debe retornar AuthResponse', () async {
      final repo = TestAuthRepository();
      final result = await repo.refreshToken('refresh-token');

      expect(result, isA<AuthResponse>());
      expect(result.accessToken, 'refreshed-access');
    });

    test('isLoggedIn debe retornar bool', () async {
      final repo = TestAuthRepository();
      final result = await repo.isLoggedIn();

      expect(result, isA<bool>());
    });
  });
}
