// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para UserDetailScreen.
//
// Cubre:
// - Estado loading → CatLoadingIndicator
// - Muestra info del usuario (username, email, createdAt)
// - Role checkboxes para cada UserRole
// - ADMIN separado con warning "ADMIN es exclusivo"
// - ADMIN checked → otros roles deshabilitados
// - No puede desmarcar propio ADMIN (isOwnProfile)
// - Save roles → confirmación → éxito/error snackbar
// - Password reset → diálogo → confirmación → éxito/error snackbar
//
// Usa UsersProvider real con MockIUsersRepository y MockAuthProvider.

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
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/users/presentation/providers/users_provider.dart';
import 'package:mundo_limpio_app/features/users/presentation/screens/user_detail_screen.dart';

class MockUsersRepository extends Mock implements IUsersRepository {}

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  String? _mockUsername;
  String? _mockRole = 'ADMIN';

  @override
  String? get username => _mockUsername;

  @override
  String? get role => _mockRole;

  @override
  String? error;

  @override
  bool get isAuthenticated => true;

  @override
  bool get isLoading => false;

  @override
  AuthStatus get status => AuthStatus.authenticated;

  void setTestUsername(String? value) {
    _mockUsername = value;
    notifyListeners();
  }

  void setTestRole(String? role) {
    _mockRole = role;
    notifyListeners();
  }

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

Widget createTestApp(
  UsersProvider usersProvider,
  MockAuthProvider authProvider,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UsersProvider>.value(value: usersProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: UserDetailScreen(userId: 1),
    ),
  );
}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls down the single ChildScrollView by given amount
Future<void> scrollDown(WidgetTester tester, double amount) async {
  await tester.drag(find.byType(SingleChildScrollView), Offset(0, amount));
  await tester.pump();
}

void main() {
  late MockUsersRepository mockRepo;
  late UsersProvider usersProvider;
  late MockAuthProvider authProvider;
  late DateTime now;
  late User testUser;

  setUp(() {
    mockRepo = MockUsersRepository();
    usersProvider = UsersProvider(mockRepo);
    authProvider = MockAuthProvider();
    now = DateTime(2024, 1, 15);
    testUser = User(
      id: 1,
      username: 'adminuser',
      email: 'admin@example.com',
      roles: [UserRole.admin],
      createdAt: now,
    );

    // Stubs por defecto
    when(() => mockRepo.getUsers()).thenAnswer((_) async => []);
    when(() => mockRepo.getUser(any())).thenAnswer((_) async => testUser);
    when(
      () => mockRepo.updateRoles(any(), any()),
    ).thenAnswer((_) async => testUser);
    when(() => mockRepo.resetPassword(any(), any())).thenAnswer((_) async {});

    authProvider.setTestUsername('different_admin');
  });

  group('UserDetailScreen', () {
    testWidgets(
      'debe mostrar indicador de carga cuando status es initial/loading',
      (tester) async {
        final completer = Completer<User>();
        when(() => mockRepo.getUser(any())).thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestApp(usersProvider, authProvider));
        await pumpUntilSettled(tester);

        expect(find.byType(CatLoadingIndicator), findsOneWidget);
      },
    );

    testWidgets('debe mostrar info del usuario cuando está cargado', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // username aparece en AppBar y en la info del perfil
      expect(find.text('adminuser'), findsAtLeast(1));
      // email
      expect(find.text('admin@example.com'), findsOneWidget);
      // fecha formateada
      expect(find.text('15/1/2024'), findsOneWidget);
    });

    testWidgets('debe mostrar sección de roles con checkboxes', (tester) async {
      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Debe mostrar ADMIN checkbox
      expect(find.text('ADMIN'), findsWidgets);

      // Debe mostrar otros roles
      expect(find.text('Stock Manager'), findsOneWidget);
      expect(find.text('Stock Operator'), findsOneWidget);
      expect(find.text('Sales Clerk'), findsOneWidget);
      expect(find.text('Producción'), findsOneWidget);
      expect(find.text('Contador'), findsOneWidget);
    });

    testWidgets(
      'debe mostrar warning de ADMIN exclusivo cuando ADMIN está marcado',
      (tester) async {
        await tester.pumpWidget(createTestApp(usersProvider, authProvider));
        await pumpUntilSettled(tester);

        // ADMIN checkbox debe estar marcado (el usuario tiene role admin)
        // y el warning debe ser visible
        expect(
          find.text(
            'ADMIN es exclusivo — no se puede combinar con otros roles',
          ),
          findsOneWidget,
        );

        // Otros roles deben estar deshabilitados (con "Desmarcá ADMIN primero")
        expect(find.text('Desmarcá ADMIN primero'), findsWidgets);
      },
    );

    testWidgets('debe deshabilitar ADMIN checkbox cuando es el propio perfil', (
      tester,
    ) async {
      // Hacer que el usuario logueado sea el mismo que el perfil
      authProvider.setTestUsername('adminuser');

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Encontrar el checkbox ADMIN
      final adminCheckbox = find.widgetWithText(CheckboxListTile, 'ADMIN');
      expect(adminCheckbox, findsOneWidget);

      // Verificar que onChanged es null (deshabilitado)
      final checkbox = tester.widget<CheckboxListTile>(adminCheckbox);
      expect(checkbox.onChanged, isNull);
    });

    testWidgets('debe permitir desmarcar ADMIN cuando NO es el propio perfil', (
      tester,
    ) async {
      // El usuario logueado es diferente (different_admin vs adminuser)
      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Encontrar ADMIN CheckboxListTile
      final adminTile = find.widgetWithText(CheckboxListTile, 'ADMIN');
      expect(adminTile, findsOneWidget);

      // Verificar que onChanged no es null
      final checkbox = tester.widget<CheckboxListTile>(adminTile);
      expect(checkbox.onChanged, isNotNull);
    });

    testWidgets('debe mostrar diálogo de confirmación al guardar roles', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Tocar botón Guardar Roles
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Roles'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Debe aparecer diálogo de confirmación
      expect(find.text('Guardar Roles'), findsWidgets);
      expect(find.text('Cancelar'), findsWidgets);
      expect(find.text('Guardar'), findsWidgets);
    });

    testWidgets('debe mostrar snackbar de éxito al guardar roles', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Tocar Guardar Roles
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Roles'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirmar en diálogo
      await tester.tap(find.text('Guardar').last);
      await pumpUntilSettled(tester);

      // Debe mostrar snackbar de éxito
      expect(find.text('Roles actualizados correctamente'), findsOneWidget);
    });

    testWidgets('debe mostrar snackbar de error si falla updateRoles', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      when(
        () => mockRepo.updateRoles(any(), any()),
      ).thenThrow(const ApiException('Error del servidor', 500));

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Tocar Guardar Roles
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar Roles'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirmar en diálogo
      await tester.tap(find.text('Guardar').last);
      await pumpUntilSettled(tester);

      // Debe mostrar SnackBar de error
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('debe mostrar diálogo de reset de contraseña', (tester) async {
      // Use larger surface to fit all content
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Tocar botón Resetear Contraseña
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Resetear Contraseña'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Debe aparecer el diálogo
      expect(find.text('Nueva Contraseña'), findsOneWidget);
      expect(find.text('Confirmar Contraseña'), findsOneWidget);
    });

    testWidgets('debe validar que la contraseña tenga al menos 6 caracteres', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Abrir diálogo de reset
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Resetear Contraseña'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Ingresar contraseña corta
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva Contraseña'),
        'abc',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar Contraseña'),
        'abc',
      );

      // Tocar Confirmar
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Debe mostrar error de validación
      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('debe validar que las contraseñas coincidan', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Abrir diálogo de reset
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Resetear Contraseña'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Ingresar contraseñas que no coinciden
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva Contraseña'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar Contraseña'),
        'different456',
      );

      // Tocar Confirmar
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Debe mostrar error
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('debe confirmar reseteo de contraseña y mostrar éxito', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Abrir diálogo de reset
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Resetear Contraseña'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Ingresar contraseña válida
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva Contraseña'),
        'newPass123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar Contraseña'),
        'newPass123',
      );

      // Tocar Confirmar en el primer diálogo
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Aparece segundo diálogo de confirmación
      expect(find.text('Confirmar Reseteo'), findsOneWidget);

      // Tocar Resetear
      await tester.tap(find.text('Resetear'));
      await pumpUntilSettled(tester);

      // Debe mostrar snackbar de éxito
      expect(find.text('Contraseña reseteada correctamente'), findsOneWidget);
      verify(() => mockRepo.resetPassword(1, 'newPass123')).called(1);
    });

    testWidgets('debe mostrar snackbar de error si falla resetPassword', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      when(
        () => mockRepo.resetPassword(any(), any()),
      ).thenThrow(const ApiException('Error del servidor', 500));

      await tester.pumpWidget(createTestApp(usersProvider, authProvider));
      await pumpUntilSettled(tester);

      // Abrir diálogo de reset
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Resetear Contraseña'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Ingresar contraseña válida
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva Contraseña'),
        'newPass123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar Contraseña'),
        'newPass123',
      );

      // Tocar Confirmar
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirmar reseteo
      await tester.tap(find.text('Resetear'));
      await pumpUntilSettled(tester);

      // Debe mostrar SnackBar de error
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
