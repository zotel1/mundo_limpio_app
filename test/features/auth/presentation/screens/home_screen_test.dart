// Pruebas de widget para HomeScreen con landing por rol.
//
// Verifica que las ActionCards se muestren según el rol:
// - ADMIN: Ver Productos, Ver Inventario, Producción, Ventas, Usuarios, Recibos
// - STOCK_MANAGER: Ver Productos, Ver Inventario, Recibos
// - STOCK_OPERATOR: Ver Productos, Ver Inventario, Recibos
// - SALES_CLERK: Ver Productos, Nueva Venta
// - PRODUCTION_OP: Ver Productos, Producción
// - ACCOUNTANT: Ver Productos + card Módulo de Costos
// - CUSTOMER: Ver Productos
//
// También verifica destinos del BottomNavigationBar por rol.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/home_screen.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  final AuthStatus _status = AuthStatus.authenticated;
  String? _role;
  List<String>? _roles;

  @override
  AuthStatus get status => _status;

  @override
  String? get role => _role;

  @override
  String? get username => 'testuser';

  @override
  String? get email => null;

  @override
  List<String>? get roles => _roles;

  @override
  String? error;

  @override
  bool get isLoading => false;

  @override
  bool get isAuthenticated => true;

  void setRole(String? role) {
    _role = role;
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
  void clearError() {}
}

Widget createTestApp(MockAuthProvider authProvider) {
  return MaterialApp(
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const HomeScreen(),
    ),
  );
}

void main() {
  late MockAuthProvider authProvider;

  setUp(() {
    authProvider = MockAuthProvider();
  });

  group('HomeScreen landing por rol — ActionCards', () {
    testWidgets('ADMIN debe ver las 6 ActionCards', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      authProvider.setRole('ADMIN');

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Ver Productos'), findsOneWidget);
      expect(find.text('Ver Inventario'), findsOneWidget);
      expect(find.text('Producción'), findsOneWidget);
      expect(find.text('Ventas'), findsOneWidget);
      expect(find.text('Usuarios'), findsOneWidget);
      expect(find.text('Recibos'), findsOneWidget);
    });

    testWidgets('ADMIN debe tener destinos [Inicio, Gestión, Perfil]', (
      tester,
    ) async {
      authProvider.setRole('ADMIN');

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Gestión'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('STOCK_MANAGER debe ver sus ActionCards', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      authProvider.setRole('STOCK_MANAGER');

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Ver Productos'), findsOneWidget);
      expect(find.text('Ver Inventario'), findsOneWidget);
      expect(find.text('Recibos'), findsOneWidget);
      // NO debe ver botones de otros roles
      expect(find.text('Ventas'), findsNothing);
      expect(find.text('Usuarios'), findsNothing);
      expect(find.text('Nueva Venta'), findsNothing);
    });

    testWidgets(
      'STOCK_MANAGER debe tener destinos [Inicio, Productos, Perfil]',
      (tester) async {
        authProvider.setRole('STOCK_MANAGER');

        await tester.pumpWidget(createTestApp(authProvider));
        await tester.pumpAndSettle();

        expect(find.text('Inicio'), findsOneWidget);
        expect(find.text('Productos'), findsOneWidget);
        expect(find.text('Perfil'), findsOneWidget);
        // NO debe ver "Gestión"
        expect(find.text('Gestión'), findsNothing);
      },
    );

    testWidgets('STOCK_OPERATOR debe ver sus ActionCards', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      authProvider.setRole('STOCK_OPERATOR');

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Ver Productos'), findsOneWidget);
      expect(find.text('Ver Inventario'), findsOneWidget);
      expect(find.text('Recibos'), findsOneWidget);
      expect(find.text('Nueva Venta'), findsNothing);
    });

    testWidgets('SALES_CLERK debe ver sus ActionCards', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      authProvider.setRole('SALES_CLERK');

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Ver Productos'), findsOneWidget);
      expect(find.text('Nueva Venta'), findsOneWidget);
      expect(find.text('Ver Inventario'), findsNothing);
    });

    testWidgets('PRODUCTION_OP debe ver sus ActionCards', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      authProvider.setRole('PRODUCTION_OP');

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Ver Productos'), findsOneWidget);
      expect(find.text('Producción'), findsOneWidget);
      expect(find.text('Ventas'), findsNothing);
    });

    testWidgets('ACCOUNTANT debe ver productos + card de costos', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      authProvider.setRole('ACCOUNTANT');

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Ver Productos'), findsOneWidget);
      // Card placeholder de costos
      expect(find.text('Módulo de Costos'), findsOneWidget);
      expect(find.textContaining('Próximamente'), findsOneWidget);
    });

    testWidgets('CUSTOMER debe ver solo Ver Productos', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      addTearDown(() => tester.view.resetPhysicalSize());

      authProvider.setRole('CUSTOMER');

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Ver Productos'), findsOneWidget);
      expect(find.text('Ventas'), findsNothing);
      expect(find.text('Ver Inventario'), findsNothing);
    });

    testWidgets('role null debe mostrar default CUSTOMER', (tester) async {
      authProvider.setRole(null);

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // CUSTOMER default: solo Ver Productos
      expect(find.text('Ver Productos'), findsOneWidget);
      expect(find.text('Ventas'), findsNothing);
    });
  });
}
