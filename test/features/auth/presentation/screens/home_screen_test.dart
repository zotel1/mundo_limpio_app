// Pruebas de widget para HomeScreen.
//
// Verifica que los botones de administración se muestren
// según el rol del usuario autenticado:
// - ADMIN: ve todos los botones
// - STOCK_MANAGER: ve solo los botones de su alcance
// - OPERATOR: no ve botones de administración
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/home_screen.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  final AuthStatus _status = AuthStatus.authenticated;
  String? _role;

  @override
  AuthStatus get status => _status;

  @override
  String? get role => _role;

  @override
  String? get username => 'testuser';

  @override
  String? error;

  @override
  bool get isLoading => false;

  @override
  bool get isAuthenticated => true;

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

  group('HomeScreen role-based buttons', () {
    testWidgets('ADMIN debe ver los botones de administración', (tester) async {
      // Arrange
      authProvider.setRole('ADMIN');

      // Act
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // Assert: botones visibles
      expect(find.text('Nueva Venta'), findsOneWidget);
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Materias Primas'), findsOneWidget);
      expect(find.text('Nueva Producción'), findsOneWidget);
      expect(find.text('Historial Producción'), findsOneWidget);
      expect(find.text('Productos'), findsOneWidget);
      expect(find.text('Escanear Recibo'), findsOneWidget);
    });

    testWidgets('STOCK_MANAGER debe ver los botones de administración', (
      tester,
    ) async {
      // Arrange
      authProvider.setRole('STOCK_MANAGER');

      // Act
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // Assert: debe ver los botones
      expect(find.text('Nueva Venta'), findsOneWidget);
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Materias Primas'), findsOneWidget);
      expect(find.text('Nueva Producción'), findsOneWidget);
      expect(find.text('Historial Producción'), findsOneWidget);
      expect(find.text('Productos'), findsOneWidget);
      expect(find.text('Escanear Recibo'), findsOneWidget);
    });

    testWidgets('OPERATOR no debe ver botones de administración', (
      tester,
    ) async {
      // Arrange
      authProvider.setRole('OPERATOR');

      // Act
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // Assert: botón "Nueva Venta" NO debe estar visible
      expect(find.text('Nueva Venta'), findsNothing);
      expect(find.text('Inventario'), findsNothing);
    });

    testWidgets('role null no debe ver botones de administración', (
      tester,
    ) async {
      // Arrange
      authProvider.setRole(null);

      // Act
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // Assert: sin botones
      expect(find.text('Nueva Venta'), findsNothing);
    });
  });
}
