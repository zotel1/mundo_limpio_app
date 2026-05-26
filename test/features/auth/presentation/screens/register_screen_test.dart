// Pruebas de widget para RegisterScreen.
//
// Cubre:
// - R2.1: Registro exitoso → SnackBar + redirige a LoginScreen
// - R2.2: Error email duplicado → muestra mensaje
// - R2.3: Validación client-side antes de llamar a la API
// - Loading state: spinner + botón deshabilitado
// - Navegación a LoginScreen
//
// Usa AuthProvider real con MockAuthRepository para probar
// la integración completa entre UI y provider.
//
// TDD: RED — test escrito antes que la implementación de la pantalla

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/storage/token_storage.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

/// Crea la app de test con AuthProvider real, mock repository
/// y GoRouter para soportar context.go().
Widget createTestApp(AuthProvider authProvider) {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    ],
  );

  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp.router(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

void main() {
  late MockAuthRepository mockRepo;
  late MockTokenStorage mockTokenStorage;
  late AuthProvider authProvider;

  setUp(() async {
    mockRepo = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();
    authProvider = AuthProvider(mockRepo, mockTokenStorage);

    // Stubs por defecto
    when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => false);
    when(() => mockRepo.register(any(), any())).thenAnswer(
      (_) async => AuthResponse(
        accessToken: 'test-access',
        refreshToken: 'test-refresh',
        role: 'user',
        username: 'newuser',
        roles: ['user'],
        createdAt: DateTime(2026, 5, 9),
      ),
    );
    when(() => mockRepo.logout()).thenAnswer((_) async {});
    when(() => mockTokenStorage.readRoles()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.readUsername()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.readEmail()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.saveRoles(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.saveUsername(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.saveEmail(any())).thenAnswer((_) async {});
    when(() => mockTokenStorage.clearAll()).thenAnswer((_) async {});

    // Resolver el estado inicial: loading → unauthenticated
    await authProvider.checkAuth();
  });

  Future<void> pumpUntilSettled(
    WidgetTester tester, {
    int maxFrames = 20,
  }) async {
    for (int i = 0; i < maxFrames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('RegisterScreen — Renderizado básico', () {
    testWidgets('debe mostrar AppBar, 3 campos, botón y link a login', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Título del AppBar + texto del botón (mismo texto en ambos)
      expect(find.text('Crear Cuenta'), findsAtLeastNWidgets(2));

      // Tres campos de texto (email + password + confirmación)
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Botón de envío
      expect(
        find.widgetWithText(ElevatedButton, 'Crear Cuenta'),
        findsOneWidget,
      );

      // Link a login
      expect(find.text('¿Ya tenés cuenta? Iniciá Sesión'), findsOneWidget);
    });
  });

  group('RegisterScreen — R2.3: Validación client-side', () {
    testWidgets('email vacío debe mostrar error de validación', (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: submit sin llenar campos
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await pumpUntilSettled(tester);

      // Assert: error de email requerido
      expect(find.text('El email es requerido'), findsOneWidget);
    });

    testWidgets('contraseña corta debe mostrar error de validación', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: llenar email y contraseña corta
      await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'ab');
      await tester.enterText(find.byType(TextFormField).at(2), 'ab');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await pumpUntilSettled(tester);

      // Assert: error de longitud mínima
      expect(
        find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('confirmación distinta debe mostrar error', (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: contraseñas no coinciden
      await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SecurePass123!',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'OtraPass456!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await pumpUntilSettled(tester);

      // Assert: error de no coincidencia
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('validación debe BLOQUEAR la llamada a register() (R2.3)', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: submit sin datos
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await pumpUntilSettled(tester);

      // Assert: NO se llamó a register
      verifyNever(() => mockRepo.register(any(), any()));
    });
  });

  group('RegisterScreen — R2.1: Registro exitoso', () {
    testWidgets(
      'registro exitoso debe mostrar SnackBar y redirigir a LoginScreen (R2.1)',
      (tester) async {
        // Arrange: register exitoso (default stub)
        await tester.pumpWidget(createTestApp(authProvider));
        await pumpUntilSettled(tester);

        // Act: llenar formulario válido y submit
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'nuevo@usuario.com',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'SecurePass123!',
        );
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'SecurePass123!',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
        await pumpUntilSettled(tester);

        // Assert: redirigió a LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(RegisterScreen), findsNothing);

        // Assert: SnackBar de éxito visible
        expect(find.text('Registro exitoso. Iniciá sesión.'), findsOneWidget);
      },
    );

    testWidgets('registro exitoso debe llamar repo.register con datos', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'nuevo@usuario.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SecurePass123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await pumpUntilSettled(tester);

      verify(
        () => mockRepo.register('nuevo@usuario.com', 'SecurePass123!'),
      ).called(1);
    });
  });

  group('RegisterScreen — R2.2: Error en registro', () {
    testWidgets('email duplicado debe mostrar mensaje de error (R2.2)', (
      tester,
    ) async {
      // Arrange: register lanza ApiException (código 409 = conflict)
      when(
        () => mockRepo.register(any(), any()),
      ).thenThrow(const ApiException('Email already registered', 409));

      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: submit con datos
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'existente@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SecurePass123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await pumpUntilSettled(tester);

      // Assert: muestra mensaje de error (procesado por ErrorHandler)
      expect(find.textContaining('Email already registered'), findsOneWidget);
    });

    testWidgets('error genérico debe mostrar mensaje por defecto', (
      tester,
    ) async {
      when(
        () => mockRepo.register(any(), any()),
      ).thenThrow(Exception('Error inesperado'));

      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SecurePass123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await pumpUntilSettled(tester);

      // Assert: mensaje genérico del provider
      expect(find.textContaining('Error inesperado'), findsOneWidget);
    });
  });

  group('RegisterScreen — Loading state', () {
    testWidgets('durante registro debe mostrar spinner y deshabilitar botón', (
      tester,
    ) async {
      // Arrange: register NO completa hasta que liberemos el completer
      final completer = Completer<AuthResponse>();
      when(
        () => mockRepo.register(any(), any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: enviar formulario válido
      await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SecurePass123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));

      // Pump un frame para que el provider se actualice a loading
      await tester.pump();

      // Assert: spinner visible
      expect(find.byType(CatLoadingIndicator), findsOneWidget);

      // Assert: botón deshabilitado (onPressed es null cuando isLoading)
      // Buscar por tipo porque el texto cambia a spinner en loading
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      // Liberar completer
      completer.complete(
        AuthResponse(
          accessToken: 'a',
          refreshToken: 'r',
          role: 'user',
          username: 'u',
          roles: ['user'],
          createdAt: DateTime(2026, 1, 1),
        ),
      );
    });
  });

  group('RegisterScreen — Navegación', () {
    testWidgets('link a login debe navegar a LoginScreen', (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: tocar link de login
      await tester.tap(find.text('¿Ya tenés cuenta? Iniciá Sesión'));
      await pumpUntilSettled(tester);

      // Assert: muestra LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
