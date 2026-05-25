import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/users/data/api/users_api.dart';
import 'package:mundo_limpio_app/features/users/data/models/user_model.dart';
import 'package:mundo_limpio_app/features/users/data/repositories/users_repository_impl.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';

class MockUsersApi extends Mock implements UsersApi {}

void main() {
  late MockUsersApi mockApi;
  late UsersRepositoryImpl repository;

  setUp(() {
    mockApi = MockUsersApi();
    repository = UsersRepositoryImpl(api: mockApi);
  });

  group('UsersRepositoryImpl', () {
    group('getUsers', () {
      test('debe retornar lista de User desde la API', () async {
        // Arrange
        final models = [
          UserModel(
            id: 1,
            username: 'User1',
            email: 'user1@email.com',
            roles: [UserRole.admin],
            createdAt: DateTime.utc(2026, 5, 25),
          ),
          UserModel(
            id: 2,
            username: 'User2',
            email: 'user2@email.com',
            roles: [UserRole.stockManager],
            createdAt: DateTime.utc(2026, 5, 24),
          ),
        ];
        when(() => mockApi.getUsers()).thenAnswer((_) async => models);

        // Act
        final result = await repository.getUsers();

        // Assert
        expect(result, isA<List<User>>());
        expect(result, hasLength(2));
        expect(result[0].username, 'User1');
        expect(result[1].username, 'User2');
        verify(() => mockApi.getUsers()).called(1);
      });

      test('debe lanzar ApiException cuando la API falla', () async {
        when(
          () => mockApi.getUsers(),
        ).thenThrow(const ApiException('Error', 500));

        expect(
          () async => await repository.getUsers(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getUser', () {
      test('debe retornar User por ID', () async {
        // Arrange
        final model = UserModel(
          id: 1,
          username: 'User1',
          email: 'user1@email.com',
          roles: [UserRole.admin],
          createdAt: DateTime.utc(2026, 5, 25),
        );
        when(() => mockApi.getUser(1)).thenAnswer((_) async => model);

        // Act
        final result = await repository.getUser(1);

        // Assert
        expect(result, isA<User>());
        expect(result.id, 1);
        expect(result.username, 'User1');
        verify(() => mockApi.getUser(1)).called(1);
      });

      test('debe lanzar ApiException cuando la API falla', () async {
        when(
          () => mockApi.getUser(999),
        ).thenThrow(const ApiException('Not found', 404));

        expect(
          () async => await repository.getUser(999),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('updateRoles', () {
      test('debe retornar User actualizado con nuevos roles', () async {
        // Arrange
        final updatedModel = UserModel(
          id: 1,
          username: 'User1',
          email: 'user1@email.com',
          roles: [UserRole.admin, UserRole.accountant],
          createdAt: DateTime.utc(2026, 5, 25),
        );
        when(
          () => mockApi.updateRoles(1, {UserRole.admin, UserRole.accountant}),
        ).thenAnswer((_) async => updatedModel);

        // Act
        final result = await repository.updateRoles(1, {
          UserRole.admin,
          UserRole.accountant,
        });

        // Assert
        expect(result, isA<User>());
        expect(
          result.roles,
          containsAll([UserRole.admin, UserRole.accountant]),
        );
        verify(
          () => mockApi.updateRoles(1, {UserRole.admin, UserRole.accountant}),
        ).called(1);
      });

      test('debe lanzar ApiException cuando la API falla', () async {
        when(
          () => mockApi.updateRoles(1, {UserRole.admin}),
        ).thenThrow(const ApiException('Bad request', 400));

        expect(
          () async => await repository.updateRoles(1, {UserRole.admin}),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('resetPassword', () {
      test('debe llamar a resetPassword de la API', () async {
        // Arrange
        when(
          () => mockApi.resetPassword(1, 'nuevaPass123'),
        ).thenAnswer((_) async {});

        // Act
        await repository.resetPassword(1, 'nuevaPass123');

        // Assert
        verify(() => mockApi.resetPassword(1, 'nuevaPass123')).called(1);
      });

      test('debe lanzar ApiException cuando la API falla', () async {
        when(
          () => mockApi.resetPassword(1, 'pass'),
        ).thenThrow(const ApiException('Forbidden', 403));

        expect(
          () async => await repository.resetPassword(1, 'pass'),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}
