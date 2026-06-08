// Prueba de compilación para AuthRepository (abstract).
// Verifica que el contrato abstracto puede ser implementado
// por una clase concreta — garantiza que la interfaz es
// correcta y completa.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/auth/domain/entities/auth_session.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';

// Implementación concreta de prueba para verificar que
// el contrato abstracto de AuthRepository es correcto.
class TestAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login(String email, String password) async {
    return const AuthSession(userId: 1, username: 'test', roles: ['user']);
  }

  @override
  Future<AuthSession> register(String email, String password) async {
    return const AuthSession(userId: 2, username: 'test', roles: ['user']);
  }

  @override
  Future<void> logout() async {
    // No-op para test
  }

  @override
  Future<AuthSession> refreshToken(String refreshToken) async {
    return const AuthSession(userId: 1, username: 'test', roles: ['user']);
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
    test('login debe retornar AuthSession', () async {
      final repo = TestAuthRepository();
      final result = await repo.login('a@b.com', 'pass');

      expect(result, isA<AuthSession>());
      expect(result.username, 'test');
    });

    test('register debe retornar AuthSession', () async {
      final repo = TestAuthRepository();
      final result = await repo.register('a@b.com', 'pass');

      expect(result, isA<AuthSession>());
    });

    test('logout no debe lanzar excepción', () async {
      final repo = TestAuthRepository();
      await repo.logout(); // No debe lanzar
    });

    test('refreshToken debe retornar AuthSession', () async {
      final repo = TestAuthRepository();
      final result = await repo.refreshToken('refresh-token');

      expect(result, isA<AuthSession>());
      expect(result.username, 'test');
    });

    test('isLoggedIn debe retornar bool', () async {
      final repo = TestAuthRepository();
      final result = await repo.isLoggedIn();

      expect(result, isA<bool>());
    });
  });
}
