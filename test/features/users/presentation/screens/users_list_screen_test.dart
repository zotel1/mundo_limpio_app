// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para UsersListScreen.
//
// Cubre:
// - Estado loading → CatLoadingIndicator
// - Lista con usuarios → ListView con Cards
// - Lista vacía → "No hay usuarios"
// - Error → mensaje + botón Reintentar
// - Pull-to-refresh → recarga
//
// Usa UsersProvider real con MockIUsersRepository.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';
import 'package:mundo_limpio_app/features/users/domain/repositories/i_users_repository.dart';
import 'package:mundo_limpio_app/features/users/presentation/providers/users_provider.dart';
import 'package:mundo_limpio_app/features/users/presentation/screens/user_detail_screen.dart';
import 'package:mundo_limpio_app/features/users/presentation/screens/users_list_screen.dart';

class MockUsersRepository extends Mock implements IUsersRepository {}

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  String? get username => 'test_admin';

  @override
  String? get role => 'ADMIN';

  @override
  String? error;

  @override
  bool get isAuthenticated => true;

  @override
  bool get isLoading => false;

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> register(String email, String password) async {}

  @override
  Future<void> logout() async {}

  @override
  void clearError() {}
}

Widget createTestApp(UsersProvider userProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UsersProvider>.value(value: userProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: MockAuthProvider()),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: const UsersListScreen(),
    ),
  );
}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
        username: 'admin',
        email: 'admin@example.com',
        roles: [UserRole.admin],
        createdAt: now,
      ),
    );
    when(() => mockRepo.updateRoles(any(), any())).thenAnswer(
      (_) async => User(
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        roles: [UserRole.admin],
        createdAt: now,
      ),
    );
    when(() => mockRepo.resetPassword(any(), any())).thenAnswer((_) async {});
  });

  group('UsersListScreen', () {
    testWidgets(
      'debe mostrar indicador de carga cuando status es initial/loading',
      (tester) async {
        when(
          () => mockRepo.getUsers(),
        ).thenAnswer((_) => Completer<List<User>>().future);

        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        expect(find.byType(CatLoadingIndicator), findsOneWidget);
      },
    );

    testWidgets('debe mostrar lista de usuarios cuando hay datos', (
      tester,
    ) async {
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
          roles: [UserRole.stockManager, UserRole.salesClerk],
          createdAt: now,
        ),
      ];
      when(() => mockRepo.getUsers()).thenAnswer((_) async => users);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('admin'), findsOneWidget);
      expect(find.text('user1'), findsOneWidget);
      expect(find.text('admin@example.com'), findsOneWidget);
      expect(find.text('user1@example.com'), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje vacío cuando no hay usuarios', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('No hay usuarios'), findsOneWidget);
    });

    testWidgets('debe mostrar error y botón de reintentar cuando falla carga', (
      tester,
    ) async {
      when(() => mockRepo.getUsers()).thenThrow(Exception('Error de red'));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('Reintentar'), findsOneWidget);

      // Ahora stub repo para que funcione y tocar Reintentar
      when(() => mockRepo.getUsers()).thenAnswer(
        (_) async => [
          User(
            id: 1,
            username: 'admin',
            email: 'admin@example.com',
            roles: [UserRole.admin],
            createdAt: now,
          ),
        ],
      );

      await tester.tap(find.text('Reintentar'));
      await pumpUntilSettled(tester);

      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('debe refrescar al hacer pull-to-refresh', (tester) async {
      when(() => mockRepo.getUsers()).thenAnswer(
        (_) async => List.generate(
          5,
          (i) => User(
            id: i + 1,
            username: 'user${i + 1}',
            email: 'user${i + 1}@example.com',
            roles: [UserRole.stockManager],
            createdAt: now,
          ),
        ),
      );

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(provider.users, hasLength(5));

      await provider.loadUsers();
      await tester.pump();

      expect(provider.status, UsersStatus.loaded);
      expect(provider.users, hasLength(5));
    });

    testWidgets('debe navegar al detalle al tocar un usuario', (tester) async {
      final users = [
        User(
          id: 1,
          username: 'admin',
          email: 'admin@example.com',
          roles: [UserRole.admin],
          createdAt: now,
        ),
      ];
      when(() => mockRepo.getUsers()).thenAnswer((_) async => users);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Tocar el usuario
      await tester.tap(find.text('admin'));
      await pumpUntilSettled(tester);

      // Debe navegar a UserDetailScreen
      expect(find.byType(UserDetailScreen), findsOneWidget);
    });
  });
}
