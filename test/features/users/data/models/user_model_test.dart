import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/users/data/models/user_model.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';

void main() {
  group('UserModel', () {
    final Map<String, dynamic> json = {
      'id': 1,
      'username': 'Usuario123',
      'email': 'user@email.com',
      'roles': ['STOCK_MANAGER'],
      'createdAt': '2026-05-25T12:00:00.000Z',
    };

    test('debe crear una instancia de UserModel desde JSON correctamente', () {
      final model = UserModel.fromJson(json);

      expect(model.id, 1);
      expect(model.username, 'Usuario123');
      expect(model.email, 'user@email.com');
      expect(model.roles, [UserRole.stockManager]);
      expect(model.createdAt, DateTime.utc(2026, 5, 25, 12, 0, 0));
    });

    test('debe convertir un UserModel a JSON correctamente', () {
      final model = UserModel(
        id: 1,
        username: 'Usuario123',
        email: 'user@email.com',
        roles: [UserRole.stockManager],
        createdAt: DateTime.utc(2026, 5, 25, 12, 0, 0),
      );
      final result = model.toJson();

      expect(result['id'], 1);
      expect(result['username'], 'Usuario123');
      expect(result['email'], 'user@email.com');
      expect(result['roles'], ['STOCK_MANAGER']);
      expect(result['createdAt'], '2026-05-25T12:00:00.000Z');
    });

    test('debe convertir un UserModel a la entidad User correctamente', () {
      final model = UserModel(
        id: 1,
        username: 'Usuario123',
        email: 'user@email.com',
        roles: [UserRole.stockManager, UserRole.admin],
        createdAt: DateTime.utc(2026, 5, 25, 12, 0, 0),
      );
      final entity = model.toEntity();

      expect(entity, isA<User>());
      expect(entity.id, 1);
      expect(entity.username, 'Usuario123');
      expect(entity.email, 'user@email.com');
      expect(entity.roles, [UserRole.stockManager, UserRole.admin]);
      expect(entity.createdAt, DateTime.utc(2026, 5, 25, 12, 0, 0));
    });

    test('debe manejar roles múltiples correctamente', () {
      final jsonMultiRole = {
        'id': 2,
        'username': 'AdminUser',
        'email': 'admin@email.com',
        'roles': ['ADMIN', 'ACCOUNTANT'],
        'createdAt': '2026-05-24T10:00:00.000Z',
      };
      final model = UserModel.fromJson(jsonMultiRole);

      expect(model.roles, containsAll([UserRole.admin, UserRole.accountant]));
    });
  });
}
