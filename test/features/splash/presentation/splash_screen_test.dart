// Pruebas de widget para SplashScreen.
//
// Verifica que la pantalla de splash renderice correctamente
// según el estado del SplashProvider:
// - idle: gato durmiendo + prompt de tap
// - waking: gato despertando, sin texto de tap
// - retry: mensaje de error + botón de reintentar
// - onAuthResolved se llama cuando auth deja de estar loading
//
// TDD: RED — test escrito antes que la implementación de SplashScreen

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/splash/domain/splash_repository.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_provider.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_screen.dart';

// ── Mocks ───────────────────────────────────────────────────────────────────

class MockSplashRepository extends Mock implements SplashRepository {}

/// Mock de AuthProvider que extiende ChangeNotifier para que Provider
/// pueda inyectarlo y los widgets reaccionen a sus cambios.
class AuthProviderMock extends ChangeNotifier implements AuthProvider {
  AuthProviderMock(AuthStatus initialStatus) : _status = initialStatus;

  AuthStatus _status;

  @override
  AuthStatus get status => _status;

  @override
  String? error;

  @override
  String? get role => null;

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

/// Crea el widget de test con los providers necesarios y GoRouter.
///
/// [splashProvider] controla el estado del splash.
/// [authProvider] controla el estado de autenticación.
/// Usa GoRouter para que SplashScreen pueda llamar context.go()
/// cuando se resuelve, sin depender de createRouter completo.
Widget createSplashTestWidget({
  required SplashProvider splashProvider,
  required AuthProviderMock authProvider,
}) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('HomePage'))),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('LoginPage'))),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<SplashProvider>.value(value: splashProvider),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
    ),
  );
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockSplashRepository mockRepo;
  late SplashProvider splashProvider;
  late AuthProviderMock authProvider;

  setUp(() {
    mockRepo = MockSplashRepository();
    // Por defecto el repositorio retorna true (backend healthy)
    when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);
  });

  group('SplashScreen — estado idle', () {
    testWidgets('debe mostrar el gato durmiendo (02_cat_sleeping.png)', (
      tester,
    ) async {
      // Arrange: estado idle, auth loading
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      // Act
      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Assert: imagen de gato durmiendo
      final image = tester.widget<Image>(find.byType(Image));
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/02_cat_sleeping.png');
    });

    testWidgets('debe mostrar el texto "Tocá para despertar al gato..."', (
      tester,
    ) async {
      // Arrange
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      // Act
      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Assert: prompt de tap visible
      expect(find.text('Tocá para despertar al gato...'), findsOneWidget);
    });

    testWidgets('debe llamar startWaking() al tocar la pantalla', (
      tester,
    ) async {
      // Arrange: estado idle
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Sanity: todavía en idle
      expect(splashProvider.isIdle, isTrue);

      // Act: tocar la pantalla
      await tester.tap(find.text('Tocá para despertar al gato...'));
      // Dejar que el timer (Duration.zero) se complete
      await tester.pump(Duration.zero);
      await tester.pump();

      // Assert: transicionó a waking
      expect(splashProvider.isWaking, isTrue);
    });
  });

  group('SplashScreen — estado waking', () {
    testWidgets('debe mostrar el gato despertando (04_cat_waking.png)', (
      tester,
    ) async {
      // Arrange: iniciar en idle y luego transicionar a waking
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Act: iniciar secuencia de despertar
      splashProvider.startWaking();
      // Dejar que el timer (Duration.zero) se complete
      await tester.pump(Duration.zero);
      await tester.pump();

      // Assert: imagen de gato despertando
      final image = tester.widget<Image>(find.byType(Image));
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/04_cat_waking.png');
    });

    testWidgets('NO debe mostrar el texto de tap prompt en estado waking', (
      tester,
    ) async {
      // Arrange
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Act: transicionar a waking
      splashProvider.startWaking();
      // Dejar que el timer (Duration.zero) se complete
      await tester.pump(Duration.zero);
      await tester.pump();

      // Assert: NO debe estar el prompt de tap
      expect(find.text('Tocá para despertar al gato...'), findsNothing);
    });
  });

  group('SplashScreen — estado retry', () {
    testWidgets('debe mostrar mensaje de error en estado retry', (
      tester,
    ) async {
      // Arrange: repo falla, estado inicial idle, transiciona a retry
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => false);
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Act: iniciar waking — el repo falla, debe ir a retry
      splashProvider.startWaking();
      await tester.pumpAndSettle();

      // Assert: mensaje de error visible
      expect(splashProvider.isRetry, isTrue);
      expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
    });

    testWidgets('debe mostrar botón de reintentar en estado retry', (
      tester,
    ) async {
      // Arrange
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => false);
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Act
      splashProvider.startWaking();
      await tester.pumpAndSettle();

      // Assert: botón de reintentar visible
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('tocar reintentar debe llamar startWaking() de nuevo', (
      tester,
    ) async {
      // Arrange: primer wake falla
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => false);
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      splashProvider.startWaking();
      await tester.pumpAndSettle();

      // Sanity: estamos en retry
      expect(splashProvider.isRetry, isTrue);

      // Configurar repo para que esta vez funcione
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);

      // Act: tocar reintentar
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      // Assert: debe haber transicionado a otro estado
      // Con animationDuration: Duration.zero y wake ok, va a resolved
      // (auth ya se resolvió durante el build si no es loading)
      // Pero auth sigue en loading, así que debería quedarse en algún estado
      // o transicionar a resolved si auth también se resuelve
      expect(splashProvider.isRetry, isFalse);
    });
  });

  group('SplashScreen — resolución de autenticación', () {
    testWidgets('llama onAuthResolved cuando auth NO está en loading', (
      tester,
    ) async {
      // Arrange: auth ya está autenticado, repo funciona
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.authenticated);

      // Act: renderizar — el build debe llamar onAuthResolved
      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Assert: después de que onAuthResolved fue llamado (por auth autenticado),
      // si startWaking se completa, debe transicionar a resolved
      // porque animationDone=true, wakeOk=true, authResolved=true
      splashProvider.startWaking();
      await tester.pumpAndSettle();

      expect(splashProvider.isResolved, isTrue);
    });

    testWidgets('NO llama onAuthResolved cuando auth sigue en loading', (
      tester,
    ) async {
      // Arrange: auth loading, repo funciona
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.loading);

      // Act
      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pump();

      // Forzar startWaking — con auth loading no debería resolver
      splashProvider.startWaking();
      await tester.pumpAndSettle();

      // Assert: NO resolvió porque auth sigue en loading
      expect(splashProvider.isResolved, isFalse);
    });
  });

  group('SplashScreen — navegación post-resolución', () {
    testWidgets('navega a / cuando autenticado al resolver', (tester) async {
      // Arrange: auth autenticado, repo funciona
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.authenticated);

      // Act: renderizar en GoRouter desde /splash
      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );

      // El build llama onAuthResolved via addPostFrameCallback
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      // Iniciar waking — con todas las condiciones OK, resuelve de inmediato
      splashProvider.startWaking();
      await tester.pump();
      await tester.pump();
      // addPostFrameCallback de _navigated → context.go('/')
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: navegó a / (muestra Text('HomePage'))
      expect(find.text('HomePage'), findsOneWidget);
    });

    testWidgets('navega a /login cuando NO autenticado al resolver', (
      tester,
    ) async {
      // Arrange: auth no autenticado, repo funciona
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);
      splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );
      authProvider = AuthProviderMock(AuthStatus.unauthenticated);

      // Act: renderizar en GoRouter desde /splash
      await tester.pumpWidget(
        createSplashTestWidget(
          splashProvider: splashProvider,
          authProvider: authProvider,
        ),
      );

      // El build llama onAuthResolved via addPostFrameCallback
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      // Iniciar waking
      splashProvider.startWaking();
      await tester.pump();
      await tester.pump();
      // addPostFrameCallback de _navigated → context.go()
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: navegó a /login (muestra Text('LoginPage'))
      expect(find.text('LoginPage'), findsOneWidget);
    });
  });
}
