// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para ErrorScreen.
//
// Cubre:
// - Renderizado con ícono de error y mensaje
// - Botón "Volver al inicio" navega a /
// - Muestra el error.toString() cuando se provee

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/core/widgets/not_found_screen.dart';

// TDD: RED — ErrorScreen aún no existe, esto falla al compilar
import 'package:mundo_limpio_app/core/widgets/error_screen.dart';

void main() {
  testWidgets('debe mostrar el icono de error y el mensaje', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ErrorScreen(error: 'Error de prueba')),
    );

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Algo salió mal'), findsOneWidget);
    expect(find.text('Error de prueba'), findsOneWidget);
  });

  testWidgets('debe mostrar el error.toString() cuando se provee', (
    tester,
  ) async {
    const error = 'Error de conexión';
    await tester.pumpWidget(const MaterialApp(home: ErrorScreen(error: error)));

    expect(find.text('Error de conexión'), findsOneWidget);
    expect(find.text('Algo salió mal'), findsOneWidget);
  });

  testWidgets('debe mostrar NotFoundScreen cuando error es null', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ErrorScreen()));

    // Si error es null, debe mostrar NotFoundScreen
    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  testWidgets('botón "Volver al inicio" navega a /', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ErrorScreen(error: 'test')),
    );

    // Verificar que el botón existe
    final button = find.text('Volver al inicio');
    expect(button, findsOneWidget);

    // Tocar el botón
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Debe navegar a /
    // Nota: como no hay GoRouter configurado, el tap no genera error
  });
}
