// Prueba de integración del flujo completo de autenticación.
//
// Simula el recorrido completo del usuario:
// 1. Usuario no autenticado → redirigido a /login
// 2. Toca "Registrate" → navega a /register
// 3. Completa formulario de registro exitoso
// 4. Redirigido a /login tras registro
// 5. Completa formulario de login exitoso
// 6. Redirigido a HomeScreen
//
// Usa un AuthProviderMock que responde a login()/register()
// cambiando el estado de autenticación, permitiendo verificar
// la integración entre Provider, GoRouter y las pantallas.
//
// TDD: VERIFY — test de integración post-implementación

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

// Mock de AuthProvider que responde a login/register cambiando estado.
//
// A diferencia del mock en app_router_test.dart, este mock
// implementa login() y register() de forma que cambian el
// estado de autenticación, permitiendo probar el flujo completo.
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _error;

  @override
  AuthStatus get status => _status;

  @override
  String? get error => _error;

  @override
  String? get role => null;

  @override
  String? get username => null;

  @override
  String? get email => null;

  @override
  List<String>? get roles => null;

  /// Indica si register() fue llamado (para asserts en test).
  bool registerCalled = false;

  /// Indica si login() fue llamado (para asserts en test).
  bool loginCalled = false;

  @override
  bool get isLoading => _status == AuthStatus.loading;

  @override
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Simula registro exitoso: status → unauthenticated, sin error.
  ///
  /// Después del registro, el usuario es redirigido a login (R2.1).
  @override
  Future<void> register(String email, String password) async {
    registerCalled = true;
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Simula login exitoso: status → authenticated, sin error.
  ///
  /// Después del login, el usuario es redirigido a HomeScreen (R3.1).
  @override
  Future<void> login(String email, String password) async {
    loginCalled = true;
    _error = null;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  Future<void> checkAuth() async {
    // No hacer nada — el test empieza con estado definido
  }

  @override
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Mock del repositorio de splash para el test de integración.
class MockSplashRepository extends Mock implements SplashRepository {}

/// Crea la app de test con GoRouter y mock de auth.
///
/// [authProvider] controla el estado de autenticación.
/// [splashProvider] controla el estado del splash.
/// [initialLocation] permite arrancar desde una ruta específica.
Widget createTestApp(
  MockAuthProvider authProvider,
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
    child: MaterialApp.router(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

void main() {
  late MockAuthProvider authProvider;
  late MockSplashRepository mockSplashRepo;
  late SplashProvider splashProvider;

  setUp(() {
    authProvider = MockAuthProvider();
    mockSplashRepo = MockSplashRepository();
    when(() => mockSplashRepo.wakeBackend()).thenAnswer((_) async => true);
    splashProvider = SplashProvider(
      mockSplashRepo,
      animationDuration: Duration.zero,
    );
  });

  /// Helper: hace pump hasta que GoRouter procesa redirects.
  Future<void> pumpUntilRouterSettles(
    WidgetTester tester, {
    int maxFrames = 20,
  }) async {
    for (int i = 0; i < maxFrames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('Auth Integration Flow', () {
    testWidgets('Flujo completo: no auth → register → login → home (R1-R6)', (
      tester,
    ) async {
      // =========================================================================
      // ESCENARIO 1: No autenticado → LoginScreen (R6.1)
      // =========================================================================
      // Arrange: usuario no autenticado (default)
      // Act: renderizar app desde /
      await tester.pumpWidget(createTestApp(authProvider, splashProvider));
      await pumpUntilRouterSettles(tester);

      // Assert: debe mostrar LoginScreen
      expect(
        find.byType(LoginScreen),
        findsOneWidget,
        reason: 'R6.1: No autenticado redirige a LoginScreen',
      );
      expect(
        find.byType(HomeScreen),
        findsNothing,
        reason: 'HomeScreen no debe mostrarse sin autenticación',
      );

      // Verificar que los elementos clave de LoginScreen están presentes
      expect(
        find.text('Iniciar Sesión'),
        findsWidgets,
        reason: 'LoginScreen debe mostrar título',
      );
      expect(
        find.byType(TextFormField),
        findsNWidgets(2),
        reason: 'LoginScreen debe tener 2 campos (email + password)',
      );

      // =========================================================================
      // ESCENARIO 2: Navegar a RegisterScreen (R2)
      // =========================================================================
      // Act: tocar el link de registro
      await tester.tap(find.text('¿No tenés cuenta? Registrate'));
      await pumpUntilRouterSettles(tester);

      // Assert: debe mostrar RegisterScreen
      expect(
        find.byType(RegisterScreen),
        findsOneWidget,
        reason: 'Debe navegar a RegisterScreen al tocar link de registro',
      );
      expect(
        find.text('Crear Cuenta'),
        findsWidgets,
        reason: 'RegisterScreen debe mostrar título',
      );

      // =========================================================================
      // ESCENARIO 3: Completar formulario de registro exitoso (R2.1)
      // =========================================================================
      // Act: llenar los 3 campos del formulario
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.at(0), 'nuevo@usuario.com');
      await tester.enterText(emailFields.at(1), 'password123');
      await tester.enterText(emailFields.at(2), 'password123');

      // Act: tocar botón de registro (segundo "Crear Cuenta" es el AppBar)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Cuenta'));
      await pumpUntilRouterSettles(tester);

      // Assert: register() fue llamado en el provider
      expect(
        authProvider.registerCalled,
        isTrue,
        reason: 'R2.1: register() debe ser llamado',
      );

      // Assert: después de registro exitoso, vuelve a LoginScreen
      expect(
        find.byType(LoginScreen),
        findsOneWidget,
        reason: 'R2.1: Registro exitoso redirige a LoginScreen',
      );
      expect(
        find.byType(RegisterScreen),
        findsNothing,
        reason: 'RegisterScreen debe desaparecer tras registro exitoso',
      );

      // =========================================================================
      // ESCENARIO 4: Completar formulario de login exitoso (R3.1)
      // =========================================================================
      // Act: llenar los 2 campos del formulario de login
      final loginEmailFields = find.byType(TextFormField);
      await tester.enterText(loginEmailFields.at(0), 'nuevo@usuario.com');
      await tester.enterText(loginEmailFields.at(1), 'password123');

      // Act: tocar botón de login (segundo "Iniciar Sesión" es el AppBar)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await pumpUntilRouterSettles(tester);

      // Assert: login() fue llamado en el provider
      expect(
        authProvider.loginCalled,
        isTrue,
        reason: 'R3.1: login() debe ser llamado',
      );

      // Assert: después de login exitoso, muestra HomeScreen
      expect(
        find.byType(HomeScreen),
        findsOneWidget,
        reason: 'R3.1: Login exitoso redirige a HomeScreen',
      );
      expect(
        find.byType(LoginScreen),
        findsNothing,
        reason: 'LoginScreen debe desaparecer tras login exitoso',
      );

      // =========================================================================
      // ESCENARIO 5: Verificar estado de autenticación (R5.1)
      // =========================================================================
      expect(
        authProvider.isAuthenticated,
        isTrue,
        reason: 'R5.1: AuthProvider debe reportar authenticated tras login',
      );
      expect(
        authProvider.error,
        isNull,
        reason: 'R5.1: No debe haber error tras login exitoso',
      );
    });
  });
}
