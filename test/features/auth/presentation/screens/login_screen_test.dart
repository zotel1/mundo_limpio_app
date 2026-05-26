// Pruebas de widget para LoginScreen.
//
// Cubre:
// - R2.3: Validación client-side antes de llamar a la API
// - R3.1: Login exitoso → redirige a HomeScreen
// - R3.2: Error de credenciales → muestra mensaje
// - R3.3: Error de red → muestra mensaje
// - Loading state: spinner + botón deshabilitado
// - Navegación a RegisterScreen
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
import 'package:mundo_limpio_app/features/auth/presentation/screens/home_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockTokenStorage extends Mock implements TokenStorage {}

/// Crea la app de test con AuthProvider real, mock repository
/// y GoRouter para soportar context.go().
Widget createTestApp(AuthProvider authProvider) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
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
    when(() => mockRepo.login(any(), any())).thenAnswer(
      (_) async => AuthResponse(
        accessToken: 'test-access',
        refreshToken: 'test-refresh',
        role: 'user',
        username: 'testuser',
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
    // Así la pantalla muestra el formulario, no el splash de carga
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

  group('LoginScreen — Renderizado básico', () {
    testWidgets('debe mostrar AppBar, campos, botón y link a registro', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Título del AppBar + texto del botón (mismo texto en ambos)
      expect(find.text('Iniciar Sesión'), findsAtLeastNWidgets(2));

      // Dos campos de texto (email + password)
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Botón de envío
      expect(
        find.widgetWithText(ElevatedButton, 'Iniciar Sesión'),
        findsOneWidget,
      );

      // Link a registro
      expect(find.text('¿No tenés cuenta? Registrate'), findsOneWidget);
    });
  });

  group('LoginScreen — R2.3: Validación client-side', () {
    testWidgets('email vacío debe mostrar error de validación', (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: submit sin llenar campos
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilSettled(tester);

      // Assert: muestra error de email requerido
      expect(find.text('El email es requerido'), findsOneWidget);
    });

    testWidgets('email inválido debe mostrar error de validación', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: llenar email inválido y submit
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'email-invalido',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilSettled(tester);

      // Assert: muestra error de email inválido
      expect(find.text('Ingresá un email válido'), findsOneWidget);
    });

    testWidgets('password vacío debe mostrar error de validación', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: llenar solo email y submit
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilSettled(tester);

      // Assert: muestra error de password requerido
      expect(find.text('La contraseña es requerida'), findsOneWidget);
    });

    testWidgets('validación debe BLOQUEAR la llamada a login() (R2.3)', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: submit sin datos (formulario inválido)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilSettled(tester);

      // Assert: NO se llamó a login
      verifyNever(() => mockRepo.login(any(), any()));
    });
  });

  group('LoginScreen — R3.1: Login exitoso', () {
    testWidgets('login exitoso debe redirigir a HomeScreen (R3.1)', (
      tester,
    ) async {
      // Arrange: login exitoso (default stub ya retorna AuthResponse)
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: llenar formulario y submit
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SecurePass123!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilSettled(tester);

      // Assert: redirigió a HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('login exitoso debe llamar repo.login con credenciales', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'usuario@test.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'MiPass123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilSettled(tester);

      verify(() => mockRepo.login('usuario@test.com', 'MiPass123!')).called(1);
    });
  });

  group('LoginScreen — R3.2/R3.3: Error en login', () {
    testWidgets('credenciales inválidas debe mostrar mensaje de error (R3.2)', (
      tester,
    ) async {
      // Arrange: mock lanza AuthException
      when(
        () => mockRepo.login(any(), any()),
      ).thenThrow(const AuthException('Credenciales inválidas'));

      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: submit con credenciales
      await tester.enterText(find.byType(TextFormField).at(0), 'bad@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilSettled(tester);

      // Assert: muestra mensaje de error (procesado por ErrorHandler)
      expect(find.textContaining('No autorizado'), findsOneWidget);
    });

    testWidgets('error de red debe mostrar mensaje (R3.3)', (tester) async {
      // Arrange: mock lanza NetworkException
      when(
        () => mockRepo.login(any(), any()),
      ).thenThrow(const NetworkException('Sin conexión'));

      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilSettled(tester);

      // Assert: muestra error de red
      expect(find.textContaining('Sin conexión'), findsOneWidget);
    });
  });

  group('LoginScreen — Loading state', () {
    testWidgets('durante login debe mostrar spinner y deshabilitar botón', (
      tester,
    ) async {
      // Arrange: login NO completa hasta que liberemos el completer
      final completer = Completer<AuthResponse>();
      when(
        () => mockRepo.login(any(), any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: enviar formulario
      await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));

      // Pump un frame para que el provider se actualice a loading
      await tester.pump();

      // Assert: spinner visible
      expect(find.byType(CatLoadingIndicator), findsOneWidget);

      // Assert: botón deshabilitado (onPressed es null cuando isLoading)
      // Buscar por tipo porque el texto cambia a spinner en loading
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      // Liberar el completer para no dejar el test colgado
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

  group('LoginScreen — Navegación', () {
    testWidgets('link a registro debe navegar a RegisterScreen', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await pumpUntilSettled(tester);

      // Act: tocar link de registro
      await tester.tap(find.text('¿No tenés cuenta? Registrate'));
      await pumpUntilSettled(tester);

      // Assert: muestra RegisterScreen
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });
}
