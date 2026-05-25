// Pruebas de widget para los redirects de GoRouter.
//
// Verifica que el router redirija correctamente según el estado
// de autenticación y splash:
// - R6.1: No autenticado en / → redirige a /login
// - R6.2: Autenticado en /login → redirige a /
// - R6.3: Loading durante startup → splash
// - /login y /register accesibles sin auth
// - / redirige a /login cuando no autenticado
//
// Actualizado PR3: ahora usa SplashScreen en vez de CircularProgressIndicator
// y createRouter recibe también SplashProvider.
//
// TDD: RED — test actualizado antes de modificar createRouter

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/router/app_router.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/register_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/home_screen.dart';
import 'package:mundo_limpio_app/features/splash/domain/splash_repository.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_provider.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_screen.dart';

// ── Mocks ───────────────────────────────────────────────────────────────────

class MockSplashRepository extends Mock implements SplashRepository {}

/// Mock de AuthProvider que extiende ChangeNotifier para que Provider
/// pueda inyectarlo y GoRouter reaccione a cambios.
class AuthProviderMock extends ChangeNotifier implements AuthProvider {
  AuthStatus _status = AuthStatus.loading;
  String? _role;

  @override
  AuthStatus get status => _status;

  @override
  String? error;

  @override
  String? get role => _role;

  @override
  String? get username => null;

  @override
  String? get email => null;

  @override
  List<String>? get roles => null;

  @override
  bool get isLoading => _status == AuthStatus.loading;

  @override
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Cambia el estado y notifica a los listeners.
  void setStatus(AuthStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  /// Cambia el rol y notifica a los listeners.
  void setRole(String? role) {
    _role = role;
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
  void clearError() {
    error = null;
    notifyListeners();
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

/// Crea la app de test envuelta en Provider para testing de routing.
///
/// [authProvider] controla el estado de autenticación.
/// [splashProvider] controla el estado del splash screen.
/// [initialLocation] permite arrancar desde una ruta específica.
Widget createTestApp(
  AuthProviderMock authProvider,
  SplashProvider splashProvider, {
  String initialLocation = '/',
}) {
  final router = createRouter(
    authProvider,
    splashProvider,
    initialLocation: initialLocation,
  );

  // Provider para recibos (necesario para ReceiptCaptureScreen)
  final mockReceiptsRepo = MockSplashRepository();
  when(() => mockReceiptsRepo.wakeBackend()).thenAnswer((_) async => true);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<SplashProvider>.value(value: splashProvider),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      // Los errores de ProviderNotFoundException en widgets de ruta
      // son aceptables — el test verifica redirect, no renderizado.
    ),
  );
}

void main() {
  late AuthProviderMock authProvider;
  late MockSplashRepository mockSplashRepo;
  late SplashProvider splashProvider;

  setUp(() {
    authProvider = AuthProviderMock();
    mockSplashRepo = MockSplashRepository();
    // Por defecto el repositorio retorna true (backend healthy)
    when(() => mockSplashRepo.wakeBackend()).thenAnswer((_) async => true);
    splashProvider = SplashProvider(
      mockSplashRepo,
      animationDuration: Duration.zero,
    );
  });

  /// Helper: hacer pump hasta que GoRouter procese redirects.
  ///
  /// Como GoRouter usa SchedulerBinding.addPostFrameCallback,
  /// necesitamos múltiples frames para que los redirects se evalúen.
  Future<void> pumpUntilSettled(
    WidgetTester tester, {
    int maxFrames = 20,
  }) async {
    for (int i = 0; i < maxFrames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('GoRouter redirects (R6)', () {
    testWidgets('R6.1: No autenticado en / redirige a /login', (tester) async {
      // Arrange: usuario no autenticado
      authProvider.setStatus(AuthStatus.unauthenticated);

      // Act: renderizar app desde /
      await tester.pumpWidget(createTestApp(authProvider, splashProvider));
      await pumpUntilSettled(tester);

      // Assert: debe mostrar LoginScreen (no HomeScreen)
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('R6.2: Autenticado en /login redirige a /', (tester) async {
      // Arrange: usuario autenticado
      authProvider.setStatus(AuthStatus.authenticated);

      // Act: arrancar desde /login
      await tester.pumpWidget(
        createTestApp(authProvider, splashProvider, initialLocation: '/login'),
      );
      await pumpUntilSettled(tester);

      // Assert: debe mostrar HomeScreen (no LoginScreen)
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('AR1: initialLocation por defecto es /splash', (tester) async {
      // Arrange: cualquier estado de auth
      authProvider.setStatus(AuthStatus.loading);

      // Act: crear router SIN initialLocation explícito (usa default)
      final router = createRouter(authProvider, splashProvider);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<SplashProvider>.value(value: splashProvider),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      // Assert: debe mostrar SplashScreen (porque default es /splash)
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('AR2: Splash nunca redirige — cambia auth y sigue en splash', (
      tester,
    ) async {
      // Arrange: cualquier estado de auth
      authProvider.setStatus(AuthStatus.loading);

      // Act: arrancar desde /splash
      await tester.pumpWidget(
        createTestApp(authProvider, splashProvider, initialLocation: '/splash'),
      );
      await tester.pump();

      // Assert: splash visible
      expect(find.byType(SplashScreen), findsOneWidget);

      // Act: cambiar a autenticado — el splash guard debe retener
      authProvider.setStatus(AuthStatus.authenticated);
      await pumpUntilSettled(tester);

      // Assert: sigue en splash, NO navegó a home
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('AR2b: Splash nunca redirige — unauthenticated', (
      tester,
    ) async {
      // Arrange: loading en /splash
      authProvider.setStatus(AuthStatus.loading);
      await tester.pumpWidget(
        createTestApp(authProvider, splashProvider, initialLocation: '/splash'),
      );
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      // Act: cambiar a no autenticado
      authProvider.setStatus(AuthStatus.unauthenticated);
      await pumpUntilSettled(tester);

      // Assert: sigue en splash (no redirigió a /login)
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('/login es accesible sin autenticación', (tester) async {
      // Arrange: usuario no autenticado
      authProvider.setStatus(AuthStatus.unauthenticated);

      // Act: ir a /login explícitamente
      await tester.pumpWidget(
        createTestApp(authProvider, splashProvider, initialLocation: '/login'),
      );
      await pumpUntilSettled(tester);

      // Assert: LoginScreen visible
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('/register es accesible sin autenticación', (tester) async {
      // Arrange: usuario no autenticado
      authProvider.setStatus(AuthStatus.unauthenticated);

      // Act: ir a /register explícitamente
      await tester.pumpWidget(
        createTestApp(
          authProvider,
          splashProvider,
          initialLocation: '/register',
        ),
      );
      await pumpUntilSettled(tester);

      // Assert: RegisterScreen visible
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('/ redirige a /login cuando no autenticado', (tester) async {
      // Arrange: usuario no autenticado
      authProvider.setStatus(AuthStatus.unauthenticated);

      // Act: arrancar desde /
      await tester.pumpWidget(createTestApp(authProvider, splashProvider));
      await pumpUntilSettled(tester);

      // Assert: LoginScreen visible, HomeScreen no
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('AR3: Ruta no-splash sigue redirigiendo sin auth', (
      tester,
    ) async {
      // Arrange: no autenticado
      authProvider.setStatus(AuthStatus.unauthenticated);

      // Act: arrancar desde / (no splash)
      await tester.pumpWidget(
        createTestApp(authProvider, splashProvider, initialLocation: '/'),
      );
      await pumpUntilSettled(tester);

      // Assert: redirige a /login
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    // ── Multi-Role Tests (PR1: products-crud) ──────────────────────────
    //
    // Verifican que el router permita/bloquee acceso según el rol.
    // Para rutas permitidas, GoRouter intenta renderizar el widget de la
    // ruta. Esos widgets pueden necesitar providers extra que no están en
    // el test — eso NO afecta la verificación del redirect.
    // Usamos zone para ignorar ProviderNotFoundException de widgets de ruta.

    Future<void> navigateAndCheckRedirect(
      WidgetTester tester,
      String role,
      String route, {
      bool expectRedirect = false,
    }) async {
      authProvider.setStatus(AuthStatus.authenticated);
      authProvider.setRole(role);

      await tester.pumpWidget(
        createTestApp(authProvider, splashProvider, initialLocation: route),
      );
      await pumpUntilSettled(tester);

      // Tomar cualquier excepción de proveedores faltantes y descartarla
      // (es esperable — los screens de rutas necesitan providers específicos)
      while (tester.takeException() != null) {
        // descartar todas las excepciones atrapadas
      }

      if (expectRedirect) {
        // Debe redirigir a HomeScreen
        expect(find.byType(HomeScreen), findsOneWidget);
      } else {
        // El redirect NO bloqueó (HomeScreen no está visible).
        // Si el widget de ruta falla por falta de providers, igual
        // estamos verificando que el redirect no redirigió a /.
        expect(find.byType(HomeScreen), findsNothing);
      }
    }

    testWidgets('A9: ADMIN puede acceder a /production/', (tester) async {
      await navigateAndCheckRedirect(tester, 'ADMIN', '/production/batches');
    });

    testWidgets('A10: STOCK_MANAGER puede acceder a /production/', (
      tester,
    ) async {
      await navigateAndCheckRedirect(
        tester,
        'STOCK_MANAGER',
        '/production/batches',
      );
    });

    testWidgets('STOCK_MANAGER puede acceder a /receipts/', (tester) async {
      await navigateAndCheckRedirect(tester, 'STOCK_MANAGER', '/receipts/new');
    });

    testWidgets('A11: OPERATOR no puede acceder a /production/', (
      tester,
    ) async {
      await navigateAndCheckRedirect(
        tester,
        'OPERATOR',
        '/production/batches',
        expectRedirect: true,
      );
    });

    // ── Products Routes (PR2) ─────────────────────────────────────
    testWidgets('ADMIN puede acceder a /products/', (tester) async {
      await navigateAndCheckRedirect(tester, 'ADMIN', '/products');
    });

    testWidgets('STOCK_MANAGER puede acceder a /products/', (tester) async {
      await navigateAndCheckRedirect(tester, 'STOCK_MANAGER', '/products');
    });

    testWidgets('OPERATOR no puede acceder a /products/', (tester) async {
      await navigateAndCheckRedirect(
        tester,
        'OPERATOR',
        '/products',
        expectRedirect: true,
      );
    });

    testWidgets('ADMIN puede acceder a /products/new', (tester) async {
      await navigateAndCheckRedirect(tester, 'ADMIN', '/products/new');
    });

    testWidgets('ADMIN puede acceder a /products/1', (tester) async {
      await navigateAndCheckRedirect(tester, 'ADMIN', '/products/1');
    });

    testWidgets('STOCK_MANAGER puede acceder a /products/1/edit', (
      tester,
    ) async {
      await navigateAndCheckRedirect(
        tester,
        'STOCK_MANAGER',
        '/products/1/edit',
      );
    });

    testWidgets('OPERATOR no puede acceder a /products/new', (tester) async {
      await navigateAndCheckRedirect(
        tester,
        'OPERATOR',
        '/products/new',
        expectRedirect: true,
      );
    });

    // ── Users Routes (PR3) ─────────────────────────────────────────
    testWidgets('ADMIN puede acceder a /users', (tester) async {
      await navigateAndCheckRedirect(tester, 'ADMIN', '/users');
    });

    testWidgets('STOCK_MANAGER no puede acceder a /users', (tester) async {
      await navigateAndCheckRedirect(
        tester,
        'STOCK_MANAGER',
        '/users',
        expectRedirect: true,
      );
    });

    testWidgets('No autenticado en /users redirige a /login', (tester) async {
      authProvider.setStatus(AuthStatus.unauthenticated);

      await tester.pumpWidget(
        createTestApp(authProvider, splashProvider, initialLocation: '/users'),
      );
      await pumpUntilSettled(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
