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

  @override
  AuthStatus get status => _status;

  @override
  String? error;

  @override
  String? get role => null;

  @override
  String? get username => null;

  @override
  bool get isLoading => _status == AuthStatus.loading;

  @override
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Cambia el estado y notifica a los listeners.
  void setStatus(AuthStatus newStatus) {
    _status = newStatus;
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

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<SplashProvider>.value(value: splashProvider),
    ],
    child: MaterialApp.router(routerConfig: router),
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

    testWidgets('R6.3: Loading durante startup muestra splash', (tester) async {
      // Arrange: estado loading por defecto

      // Act: renderizar app desde /
      await tester.pumpWidget(createTestApp(authProvider, splashProvider));
      // Solo un frame — SplashScreen debe mostrarse
      await tester.pump();

      // Assert: debe mostrar SplashScreen (no CircularProgressIndicator)
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
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

    testWidgets('Cambio loading → unauthenticated redirige a /login', (
      tester,
    ) async {
      // Arrange: empezar en loading (splash)
      await tester.pumpWidget(createTestApp(authProvider, splashProvider));
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      // Act: cambiar a no autenticado
      authProvider.setStatus(AuthStatus.unauthenticated);
      await pumpUntilSettled(tester);

      // Assert: ahora en LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Cambio loading → authenticated redirige a /', (tester) async {
      // Arrange: empezar en loading
      await tester.pumpWidget(createTestApp(authProvider, splashProvider));
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      // Act: cambiar a autenticado
      authProvider.setStatus(AuthStatus.authenticated);
      await pumpUntilSettled(tester);

      // Assert: ahora en HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
