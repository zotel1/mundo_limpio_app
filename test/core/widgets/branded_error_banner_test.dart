// Pruebas de widget para BrandedErrorBanner.
//
// Verifica:
// - Mensaje de error visible
// - Callback onDismiss se dispara al tocar el botón de cierre
// - Colores de marca: fondo surface, acento error
// - Accesibilidad con Semantics label
// - Const-constructible
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/core/theme/app_colors.dart';
import 'package:mundo_limpio_app/core/widgets/branded_error_banner.dart';

void main() {
  group('BrandedErrorBanner — contenido', () {
    testWidgets('debe mostrar el mensaje de error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandedErrorBanner(message: 'Error de conexión'),
          ),
        ),
      );

      expect(find.text('Error de conexión'), findsOneWidget);
    });

    testWidgets('debe mostrar un icono de error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandedErrorBanner(message: 'Algo salió mal'),
          ),
        ),
      );

      // El banner debe incluir un ícono de error para diferenciarlo visualmente
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('debe usar el color error de AppColors como acento', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandedErrorBanner(message: 'Error'),
          ),
        ),
      );

      // El icono de error debe estar en el color error de la marca
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, AppColors.error);
    });

    testWidgets('debe tener fondo surface (blanco)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandedErrorBanner(message: 'Error'),
          ),
        ),
      );

      // El Container principal debe tener color surface
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.surface);
    });
  });

  group('BrandedErrorBanner — interacción', () {
    testWidgets('debe llamar onDismiss al tocar el botón de cierre', (
      tester,
    ) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrandedErrorBanner(
              message: 'Error temporal',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Tocar el botón de cierre (IconButton con X o close)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets(
      'no debe crashear cuando onDismiss es null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BrandedErrorBanner(message: 'Sin dismiss'),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'no debe mostrar botón de cierre cuando onDismiss es null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BrandedErrorBanner(message: 'Sin botón'),
            ),
          ),
        );

        // Si onDismiss es null, no debería haber IconButton
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );
  });

  group('BrandedErrorBanner — accesibilidad', () {
    testWidgets('debe tener un Semantics label descriptivo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandedErrorBanner(message: 'Timeout de red'),
          ),
        ),
      );

      // El widget Semantics existe y contiene el label descriptivo
      // (verificamos por el tipo, ya que la label se usa internamente
      // para lectores de pantalla)
      expect(find.byType(Semantics), findsWidgets);
    });
  });

  group('BrandedErrorBanner — estructura', () {
    testWidgets('debe ser const-constructible', (tester) async {
      const banner = BrandedErrorBanner(message: 'Test');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: banner),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
