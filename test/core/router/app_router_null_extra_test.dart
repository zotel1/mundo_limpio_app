// Tests de widget para rutas GoRouter con state.extra nulo.
//
// B3-01: /sales/result con null extra → error con botón Volver al home
// B3-02: /receipts/review con null extra → error con botón Volver a /receipts/new
// B3-03: /receipts/confirmed con null extra → error con botón Volver a /receipts/new
//
// TDD: RED — tests escritos antes de arreglar los route builders.
// Actualmente las rutas muestran Scaffold("Error: datos no disponibles")
// sin navegación. Después del fix deben mostrar ErrorScreen con botón Volver.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/router/app_router.dart';
import 'package:mundo_limpio_app/core/widgets/error_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sale_result_screen.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_review_screen.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_confirmed_screen.dart';
import 'package:mundo_limpio_app/features/splash/domain/splash_repository.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_provider.dart';

// ── Mocks ───────────────────────────────────────────────────────────────────

class MockSplashRepository extends Mock implements SplashRepository {}

/// Mock de AuthProvider que extiende ChangeNotifier para que Provider
/// pueda inyectarlo y GoRouter reaccione a cambios.
class AuthProviderMock extends ChangeNotifier implements AuthProvider {
  AuthStatus _status = AuthStatus.loading;
  List<String>? _roles;

  @override
  AuthStatus get status => _status;

  @override
  String? error;

  @override
  String? get role => _roles?.isNotEmpty == true ? _roles!.first : null;

  @override
  String? get username => null;

  @override
  String? get email => null;

  @override
  List<String>? get roles => _roles;

  @override
  bool get isLoading => _status == AuthStatus.loading;

  @override
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void setStatus(AuthStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void setRole(String? role) {
    _roles = role != null ? [role] : null;
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

/// Helper: hacer pump hasta que GoRouter procese redirects.
Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Navega a [route] sin state.extra y espera a que GoRouter procese.
Future<void> goToRoute(WidgetTester tester, String route) async {
  await tester.pumpWidget(
    createTestApp(
      _sharedAuthProvider!,
      _sharedSplashProvider!,
      initialLocation: route,
    ),
  );
  await pumpUntilSettled(tester);

  // Descartar excepciones de providers faltantes (esperables en widget tests)
  while (tester.takeException() != null) {
    // descartar
  }
}

// ── Shared state (inicializado en setUp) ─────────────────────────────────────
AuthProviderMock? _sharedAuthProvider;
SplashProvider? _sharedSplashProvider;

void main() {
  late AuthProviderMock authProvider;
  late MockSplashRepository mockSplashRepo;
  late SplashProvider splashProvider;

  setUp(() {
    authProvider = AuthProviderMock();
    mockSplashRepo = MockSplashRepository();
    when(() => mockSplashRepo.wakeBackend()).thenAnswer((_) async => true);
    splashProvider = SplashProvider(
      mockSplashRepo,
      animationDuration: Duration.zero,
    );

    // Autenticado como ADMIN para que los redirects no bloqueen el acceso
    authProvider.setStatus(AuthStatus.authenticated);
    authProvider.setRole('ADMIN');

    // Compartir para goToRoute
    _sharedAuthProvider = authProvider;
    _sharedSplashProvider = splashProvider;
  });

  // ── B3-01: /sales/result null extra ────────────────────────────────────

  testWidgets(
    'B3-01: /sales/result con null state.extra muestra error con botón Volver',
    (tester) async {
      // TDD: RED — actualmente muestra Scaffold("Error: datos de venta no disponibles"),
      // no ErrorScreen. Este test debe FALLAR hasta que se arregle app_router.dart.

      // Act: navegar a /sales/result sin extra
      await goToRoute(tester, '/sales/result');

      // Assert: debe mostrar ErrorScreen (no un Scaffold muerto)
      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(find.byType(SaleResultScreen), findsNothing);

      // Assert: debe mostrar el mensaje de error
      expect(find.text('Error: datos de venta no disponibles'), findsOneWidget);

      // Assert: debe existir un botón Volver
      expect(find.text('Volver'), findsOneWidget);
    },
  );

  // ── B3-02: /receipts/review null extra ─────────────────────────────────

  testWidgets(
    'B3-02: /receipts/review con null state.extra muestra error con botón Volver',
    (tester) async {
      // TDD: RED — actualmente muestra Scaffold("Error: datos de recibo no disponibles"),
      // no ErrorScreen.

      // Act: navegar a /receipts/review sin extra
      await goToRoute(tester, '/receipts/review');

      // Assert: debe mostrar ErrorScreen
      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(find.byType(ReceiptReviewScreen), findsNothing);

      // Assert: mensaje de error específico
      expect(
        find.text('Error: datos de recibo no disponibles'),
        findsOneWidget,
      );

      // Assert: botón Volver presente
      expect(find.text('Volver'), findsOneWidget);
    },
  );

  // ── B3-03: /receipts/confirmed null extra ──────────────────────────────

  testWidgets(
    'B3-03: /receipts/confirmed con null state.extra muestra error con botón Volver',
    (tester) async {
      // TDD: RED — actualmente muestra Scaffold("Error: datos de compra no disponibles"),
      // no ErrorScreen.

      // Act: navegar a /receipts/confirmed sin extra
      await goToRoute(tester, '/receipts/confirmed');

      // Assert: debe mostrar ErrorScreen
      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(find.byType(ReceiptConfirmedScreen), findsNothing);

      // Assert: mensaje de error específico
      expect(
        find.text('Error: datos de compra no disponibles'),
        findsOneWidget,
      );

      // Assert: botón Volver presente
      expect(find.text('Volver'), findsOneWidget);
    },
  );
}
