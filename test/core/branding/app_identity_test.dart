// Pruebas de identidad de la aplicación MundoLimpio.
//
// Verifica que el ThemeData se aplique desde AppTheme.light en app.dart,
// que el splash screen tenga branding (navy bg + LogoWidget),
// y que los archivos de configuración nativos reflejen la identidad.
//
// TDD: RED — test escrito antes que las modificaciones

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/app.dart';
import 'package:mundo_limpio_app/core/theme/app_colors.dart';
import 'package:mundo_limpio_app/core/router/app_router.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/splash/domain/splash_repository.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_provider.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Resuelve una ruta relativa desde la raíz del proyecto.
String projectPath(String relativePath) => relativePath;

// ---------------------------------------------------------------------------
// Mock de AuthProvider para tests de la app.
// ---------------------------------------------------------------------------

class _AppIdentityAuthMock extends ChangeNotifier implements AuthProvider {
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

/// Mock del repositorio de splash para tests de branding.
class _MockSplashRepository extends Mock implements SplashRepository {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // Task 4.1 — App Theme desde AppTheme.light
  // =========================================================================
  group('App Theme — MundoLimpioApp usa AppTheme.light', () {
    testWidgets('MaterialApp.router debe aplicar AppTheme.light como theme', (
      tester,
    ) async {
      // TDD: RED — app.dart todavía usa ThemeData(colorSchemeSeed: green)
      final authMock = _AppIdentityAuthMock();
      authMock.setStatus(AuthStatus.unauthenticated);

      final mockRepo = _MockSplashRepository();
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);
      final splashProvider = SplashProvider(
        mockRepo,
        animationDuration: Duration.zero,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authMock),
            ChangeNotifierProvider<SplashProvider>.value(value: splashProvider),
          ],
          child: const MundoLimpioApp(),
        ),
      );
      // Necesitamos varios frames para que GoRouter procese redirects
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Encontrar el MaterialApp.router widget
      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);

      final materialApp = tester.widget<MaterialApp>(materialAppFinder);
      final theme = materialApp.theme;

      // La propiedad clave: el theme debe ser exactamente AppTheme.light
      // Verificamos que el color primario del tema sea navy
      expect(
        theme?.colorScheme.primary,
        AppColors.primary,
        reason:
            'El tema debe usar AppTheme.light cuyo primary es navy (#1E2238)',
      );
      // useMaterial3 debe ser true
      expect(theme?.useMaterial3, true);
    });
  });

  // =========================================================================
  // Task 4.6 — Branded Splash Screen
  // =========================================================================
  group('Branded Splash Screen', () {
    late _AppIdentityAuthMock authMock;
    late _MockSplashRepository mockSplashRepo;
    late SplashProvider splashProvider;

    setUp(() {
      authMock = _AppIdentityAuthMock();
      mockSplashRepo = _MockSplashRepository();
      when(() => mockSplashRepo.wakeBackend()).thenAnswer((_) async => true);
      splashProvider = SplashProvider(
        mockSplashRepo,
        animationDuration: Duration.zero,
      );
      // loading state activa la ruta /splash
    });

    /// Helper: hacer pump hasta que el router se estabilice.
    Future<void> pumpUntilSettled(
      WidgetTester tester, {
      int maxFrames = 10,
    }) async {
      for (int i = 0; i < maxFrames; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('splash screen debe tener fondo navy', (tester) async {
      // TDD: RED — splash actual usa Scaffold por defecto (blanco)
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authMock),
            ChangeNotifierProvider<SplashProvider>.value(value: splashProvider),
          ],
          child: MaterialApp.router(
            routerConfig: createRouter(
              authMock,
              splashProvider,
              initialLocation: '/splash',
            ),
          ),
        ),
      );
      await pumpUntilSettled(tester);

      // Encontrar el Scaffold del splash
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(
        scaffold.backgroundColor,
        AppColors.primary,
        reason: 'El splash debe tener fondo navy (#1E2238)',
      );
    });

    testWidgets('splash screen debe mostrar el SplashScreen interactivo', (
      tester,
    ) async {
      // TDD: GREEN — PR3: splash interactivo con gato mascota
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authMock),
            ChangeNotifierProvider<SplashProvider>.value(value: splashProvider),
          ],
          child: MaterialApp.router(
            routerConfig: createRouter(
              authMock,
              splashProvider,
              initialLocation: '/splash',
            ),
          ),
        ),
      );
      await pumpUntilSettled(tester);

      // Debe existir un SplashScreen en el árbol
      expect(
        find.byType(SplashScreen),
        findsOneWidget,
        reason: 'El splash debe mostrar el SplashScreen interactivo',
      );
    });

    testWidgets('splash screen debe mostrar imagen del gato en estado idle', (
      tester,
    ) async {
      // TDD: GREEN — PR3: gato durmiendo + prompt de tap
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authMock),
            ChangeNotifierProvider<SplashProvider>.value(value: splashProvider),
          ],
          child: MaterialApp.router(
            routerConfig: createRouter(
              authMock,
              splashProvider,
              initialLocation: '/splash',
            ),
          ),
        ),
      );
      await pumpUntilSettled(tester);

      // Debe mostrar la imagen del gato (Image widget)
      expect(
        find.byType(Image),
        findsOneWidget,
        reason: 'El splash debe mostrar la imagen del gato mascota',
      );

      // Debe mostrar el prompt de tap para interactuar
      expect(
        find.text('Tocá para despertar al gato...'),
        findsOneWidget,
        reason: 'El splash idle debe invitar al usuario a interactuar',
      );
    });
  });

  // =========================================================================
  // Task 4.3 — Android Manifest Label validation
  // =========================================================================
  group('AndroidManifest.xml — label', () {
    test('android:label debe ser "Mundo Limpio"', () {
      // TDD: RED — valor actual es "mundo_limpio_app"
      final path = projectPath('android/app/src/main/AndroidManifest.xml');
      final file = File(path);
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();

      // Buscar el atributo android:label en el <application> tag
      expect(
        content.contains('android:label="Mundo Limpio"'),
        isTrue,
        reason: 'El label de la app en Android debe ser "Mundo Limpio"',
      );
    });
  });

  // =========================================================================
  // Task 4.4 — Web Manifest validation
  // =========================================================================
  group('web/manifest.json — identidad', () {
    late Map<String, dynamic> manifest;

    setUpAll(() {
      final path = projectPath('web/manifest.json');
      final file = File(path);
      final content = file.readAsStringSync();
      manifest = jsonDecode(content) as Map<String, dynamic>;
    });

    test('name debe ser "Mundo Limpio"', () {
      // TDD: RED — valor actual es "mundo_limpio_app"
      expect(manifest['name'], 'Mundo Limpio');
    });

    test('short_name debe ser "MundoLimpio"', () {
      // TDD: RED — valor actual es "mundo_limpio_app"
      expect(manifest['short_name'], 'MundoLimpio');
    });

    test('description debe ser la descripción de la app', () {
      // TDD: RED — valor actual es "A new Flutter project."
      expect(
        manifest['description'],
        'Gestión de inventario y ventas de productos de limpieza',
      );
    });

    test('background_color debe ser navy #1E2238', () {
      // TDD: RED — valor actual es "#0175C2"
      expect(manifest['background_color'], '#1E2238');
    });

    test('theme_color debe ser navy #1E2238', () {
      // TDD: RED — valor actual es "#0175C2"
      expect(manifest['theme_color'], '#1E2238');
    });
  });

  // =========================================================================
  // Task 4.5 (validation) — Web index.html meta tags
  // =========================================================================
  group('web/index.html — metadatos', () {
    late String html;

    setUpAll(() {
      final path = projectPath('web/index.html');
      final file = File(path);
      html = file.readAsStringSync();
    });

    test('title debe ser "Mundo Limpio"', () {
      // TDD: RED — valor actual es "mundo_limpio_app"
      expect(html.contains('<title>Mundo Limpio</title>'), isTrue);
    });

    test('apple-mobile-web-app-title debe ser "Mundo Limpio"', () {
      // TDD: RED — valor actual es "mundo_limpio_app"
      expect(
        html.contains(
          '<meta name="apple-mobile-web-app-title" content="Mundo Limpio">',
        ),
        isTrue,
      );
    });

    test('meta description debe describir la app', () {
      // TDD: RED — valor actual es "A new Flutter project."
      expect(
        html.contains(
          '<meta name="description" content="Gestión de inventario y ventas de productos de limpieza">',
        ),
        isTrue,
      );
    });
  });
}
