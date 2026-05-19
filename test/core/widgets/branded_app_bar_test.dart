// Pruebas de widget para BrandedAppBar.
//
// Verifica que el AppBar de marca cumpla con los tokens visuales:
// - Fondo navy (AppColors.primary)
// - Título blanco con el texto correcto
// - Elevación 0 (flat, Material moderno)
// - Actions visibles cuando se pasan
// - implementa PreferredSizeWidget
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/core/theme/app_colors.dart';
import 'package:mundo_limpio_app/core/theme/app_text_styles.dart';
import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';

/// Helper para envolver un widget en MaterialApp y Scaffold
/// evitando errores de contexto Material.
Widget wrapWithMaterial({required Widget child}) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('BrandedAppBar — estilos de marca', () {
    testWidgets('debe tener fondo navy (AppColors.primary)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: const BrandedAppBar(title: 'Test')),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppColors.primary);
    });

    testWidgets('debe mostrar título en blanco con el texto correcto', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: const BrandedAppBar(title: 'Login')),
        ),
      );

      // El texto "Login" debe ser visible
      expect(find.text('Login'), findsOneWidget);

      // El título debe estar en blanco
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final titleText = appBar.title as Text;
      expect(titleText.style?.color, Colors.white);
    });

    testWidgets('debe usar titleLarge con el color blanco override', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: const BrandedAppBar(title: 'Home')),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final titleText = appBar.title as Text;
      expect(titleText.style?.fontSize, AppTextStyles.titleLarge.fontSize);
      expect(titleText.style?.fontWeight, AppTextStyles.titleLarge.fontWeight);
    });

    testWidgets('debe tener elevación 0 (flat)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: const BrandedAppBar(title: 'Flat')),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.elevation, 0.0);
    });

    testWidgets(
      'debe mostrar iconos de actions en blanco cuando se pasan actions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: BrandedAppBar(
                title: 'Actions',
                actions: const [Icon(Icons.search), Icon(Icons.more_vert)],
              ),
            ),
          ),
        );

        // Los iconos de action deben renderizarse
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);

        // El foreground color del AppBar debe ser blanco
        // (afecta iconos y texto por igual)
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.foregroundColor, Colors.white);
      },
    );

    testWidgets('automaticallyImplyLeading debe ser true por defecto', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: const BrandedAppBar(title: 'Back')),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.automaticallyImplyLeading, true);
    });

    testWidgets(
      'automaticallyImplyLeading debe ser false cuando se pasa false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: const BrandedAppBar(
                title: 'No Back',
                automaticallyImplyLeading: false,
              ),
            ),
          ),
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.automaticallyImplyLeading, false);
      },
    );
  });

  group('BrandedAppBar — estructura', () {
    testWidgets('debe implementar PreferredSizeWidget', (tester) async {
      const appBar = BrandedAppBar(title: 'Check');
      expect(appBar, isA<PreferredSizeWidget>());
    });

    testWidgets('debe ser const-constructible', (tester) async {
      // Si esto compila, el constructor es const
      const appBar = BrandedAppBar(title: 'Const');
      await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: appBar)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin actions debe renderizar correctamente (null actions)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: const BrandedAppBar(title: 'Solo')),
        ),
      );

      expect(find.text('Solo'), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      // actions debe estar vacío o ser null
      expect(appBar.actions, isNull);
    });
  });
}
