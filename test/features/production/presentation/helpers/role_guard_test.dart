// TDD: RED — test escrito antes que la implementación
//
// Pruebas unitarias para RoleGuard widget.
//
// Verifica que:
// - Muestra el child cuando el role coincide con requiredRole
// - Muestra AccessDeniedScreen cuando el role no coincide
// - Muestra AccessDeniedScreen cuando el role es null

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/helpers/role_guard.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget buildTestApp({required Widget child, required String requiredRole}) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: RoleGuard(requiredRole: requiredRole, child: child),
      ),
    );
  }

  group('RoleGuard', () {
    testWidgets('debe mostrar child cuando el role coincide', (tester) async {
      when(() => mockAuthProvider.role).thenReturn('ADMIN');

      await tester.pumpWidget(buildTestApp(
        requiredRole: 'ADMIN',
        child: const Text('Admin content'),
      ));

      expect(find.text('Admin content'), findsOneWidget);
      expect(find.textContaining('Access Denied'), findsNothing);
    });

    testWidgets('debe mostrar denied screen cuando el role no coincide',
        (tester) async {
      when(() => mockAuthProvider.role).thenReturn('OPERATOR');

      await tester.pumpWidget(buildTestApp(
        requiredRole: 'ADMIN',
        child: const Text('Admin content'),
      ));

      expect(find.text('Admin content'), findsNothing);
      expect(find.textContaining('Access Denied'), findsOneWidget);
    });

    testWidgets('debe mostrar denied screen cuando role es null',
        (tester) async {
      when(() => mockAuthProvider.role).thenReturn(null);

      await tester.pumpWidget(buildTestApp(
        requiredRole: 'ADMIN',
        child: const Text('Admin content'),
      ));

      expect(find.text('Admin content'), findsNothing);
      expect(find.textContaining('Access Denied'), findsOneWidget);
    });
  });
}
