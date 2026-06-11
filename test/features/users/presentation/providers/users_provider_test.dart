// TDD: RED — test escrito antes que la implementación
//
// Pruebas unitarias para UsersProvider.
//
// Verifica:
// - Estado inicial correcto
// - loadUsers, loadUser cargan datos
// - updateRoles, resetPassword exitosos
// - ChangeNotifier notifica listeners
// - ApiException y error genérico manejados correctamente

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';
import 'package:mundo_limpio_app/features/users/domain/repositories/i_users_repository.dart';
import 'package:mundo_limpio_app/features/users/presentation/providers/users_provider.dart';

class MockUsersRepository extends Mock implements IUsersRepository {}

void main() {
  late MockUsersRepository mockRepo;
  late UsersProvider provider;
  late DateTime now;

  setUp(() {
    mockRepo = MockUsersRepository();
    provider = UsersProvider(mockRepo);
    now = DateTime(2024, 1, 15);

    // Stubs por defecto
    when(() => mockRepo.getUsers()).thenAnswer((_) async => []);
    when(() => mockRepo.getUser(any())).thenAnswer(
      (_) async => User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        roles: [UserRole.admin],
        createdAt: now,
      ),
    );
    when(() => mockRepo.updateRoles(any(), any())).thenAnswer(
      (_) async => User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        roles: [UserRole.stockManager],
        createdAt: now,
      ),
    );
    when(() => mockRepo.resetPassword(any(), any())).thenAnswer((_) async {});
  });

  group('estado inicial', () {
    test('debe iniciar con status initial', () {
      expect(provider.status, UsersStatus.initial);
    });

    test('debe iniciar sin error', () {
      expect(provider.error, isNull);
    });

    test('isLoading debe ser false al iniciar', () {
      expect(provider.isLoading, isFalse);
    });

    test('debe iniciar con lista vacía', () {
      expect(provider.users, isEmpty);
    });

    test('selectedUser debe ser null al iniciar', () {
      expect(provider.selectedUser, isNull);
    });
  });

  group('loadUsers', () {
    test('debe cargar usuarios y setear status loaded', () async {
      final users = [
        User(
          id: 1,
          username: 'admin',
          email: 'admin@example.com',
          roles: [UserRole.admin],
          createdAt: now,
        ),
        User(
          id: 2,
          username: 'user1',
          email: 'user1@example.com',
          roles: [UserRole.stockManager],
          createdAt: now,
        ),
      ];
      when(() => mockRepo.getUsers()).thenAnswer((_) async => users);

      await provider.loadUsers();

      expect(provider.status, UsersStatus.loaded);
      expect(provider.users, users);
      expect(provider.isLoading, isFalse);
    });

    test('debe cargar lista vacía y setear status loaded', () async {
      when(() => mockRepo.getUsers()).thenAnswer((_) async => []);

      await provider.loadUsers();

      expect(provider.status, UsersStatus.loaded);
      expect(provider.users, isEmpty);
    });

    test('debe setear error cuando falla con ApiException', () async {
      when(
        () => mockRepo.getUsers(),
      ).thenThrow(const UnknownApiException('Error de red', 500));

      await provider.loadUsers();

      expect(provider.status, UsersStatus.error);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('debe setear error genérico con excepción desconocida', () async {
      when(() => mockRepo.getUsers()).thenThrow(Exception('Algo salió mal'));

      await provider.loadUsers();

      expect(provider.status, UsersStatus.error);
      expect(provider.error, 'Error inesperado. Intentalo de nuevo.');
    });
  });

  group('loadUser', () {
    test('debe cargar un usuario y setear selectedUser', () async {
      const userId = 5;
      final user = User(
        id: userId,
        username: 'detailuser',
        email: 'detail@example.com',
        roles: [UserRole.admin],
        createdAt: now,
      );
      when(() => mockRepo.getUser(userId)).thenAnswer((_) async => user);

      await provider.loadUser(userId);

      expect(provider.status, UsersStatus.loaded);
      expect(provider.selectedUser, user);
    });

    test('debe setear error si getUser falla', () async {
      when(
        () => mockRepo.getUser(any()),
      ).thenThrow(const UnknownApiException('No encontrado', 404));

      await provider.loadUser(99);

      expect(provider.status, UsersStatus.error);
      expect(provider.error, isNotNull);
    });
  });

  group('updateRoles', () {
    test('debe actualizar roles exitosamente', () async {
      const userId = 1;
      final roles = {UserRole.stockManager};

      await provider.updateRoles(userId, roles);

      expect(provider.status, UsersStatus.loaded);
      expect(provider.selectedUser, isNotNull);
      expect(provider.selectedUser!.roles, [UserRole.stockManager]);
      verify(() => mockRepo.updateRoles(userId, roles)).called(1);
    });

    test('debe setear error si updateRoles falla', () async {
      when(
        () => mockRepo.updateRoles(any(), any()),
      ).thenThrow(const UnknownApiException('Error al actualizar', 500));

      await provider.updateRoles(1, {UserRole.admin});

      expect(provider.status, UsersStatus.error);
      expect(provider.error, isNotNull);
    });

    test('debe estar en estado updatingRole durante la operación', () async {
      // Usar un completer para observar el estado intermedio
      final completer = Completer<User>();
      when(
        () => mockRepo.updateRoles(any(), any()),
      ).thenAnswer((_) => completer.future);

      // Iniciar operación pero no completarla
      final future = provider.updateRoles(1, {UserRole.stockManager});

      expect(provider.status, UsersStatus.updatingRole);

      completer.complete(
        User(
          id: 1,
          username: 'test',
          email: 'test@test.com',
          roles: [UserRole.stockManager],
          createdAt: now,
        ),
      );
      await future;
    });
  });

  group('resetPassword', () {
    test('debe resetear contraseña exitosamente', () async {
      await provider.resetPassword(1, 'newPass123');

      expect(provider.status, UsersStatus.loaded);
      verify(() => mockRepo.resetPassword(1, 'newPass123')).called(1);
    });

    test('debe setear error si resetPassword falla', () async {
      when(
        () => mockRepo.resetPassword(any(), any()),
      ).thenThrow(const UnknownApiException('Error al resetear', 500));

      await provider.resetPassword(1, 'newPass123');

      expect(provider.status, UsersStatus.error);
      expect(provider.error, isNotNull);
    });

    test(
      'debe estar en estado resettingPassword durante la operación',
      () async {
        final completer = Completer<void>();
        when(
          () => mockRepo.resetPassword(any(), any()),
        ).thenAnswer((_) => completer.future);

        final future = provider.resetPassword(1, 'newPass123');

        expect(provider.status, UsersStatus.resettingPassword);

        completer.complete();
        await future;
      },
    );
  });

  group('ChangeNotifier', () {
    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });

    test('debe notificar listeners durante loadUsers', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadUsers();

      expect(notifyCount, greaterThan(0));
    });

    test('debe notificar listeners durante updateRoles', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.updateRoles(1, {UserRole.stockManager});

      expect(notifyCount, greaterThan(0));
    });

    test('debe notificar listeners durante resetPassword', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.resetPassword(1, 'newPass123');

      expect(notifyCount, greaterThan(0));
    });
  });
}
