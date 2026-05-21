// Pruebas de widget para CatLoadingIndicator.
//
// Verifica que cada constructor nombrado renderice la imagen de gato
// correcta según el mapeo definido en R7:
// - .general()     → 01_cat_standing.png   (gato parado — carga general)
// - .inventory()   → 07_cat_broom.png      (gato con escoba — inventario)
// - .small()       → 06_cat_broom_small.png (escoba chica — spinners inline)
// - .decorative()  → 03_cat_laundry.png    (gato lavando — decorativo)
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';

void main() {
  group('CatLoadingIndicator — variantes de imagen', () {
    testWidgets('.general() debe usar 01_cat_standing.png', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CatLoadingIndicator.general())),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/01_cat_standing.png');
    });

    testWidgets('.inventory() debe usar 07_cat_broom.png', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CatLoadingIndicator.inventory()),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/07_cat_broom.png');
    });

    testWidgets('.small() debe usar 06_cat_broom_small.png', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CatLoadingIndicator.small())),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/06_cat_broom_small.png');
    });

    testWidgets('.decorative() debe usar 03_cat_laundry.png', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CatLoadingIndicator.decorative()),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/03_cat_laundry.png');
    });
  });

  group('CatLoadingIndicator — tamaño y accesibilidad', () {
    testWidgets('.general() con size personalizado debe reflejar dimensiones', (
      tester,
    ) async {
      const customSize = 120.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CatLoadingIndicator.general(size: customSize)),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, customSize);
      expect(image.height, customSize);
    });

    testWidgets('.small() por defecto debe ser 24', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CatLoadingIndicator.small())),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 24.0);
      expect(image.height, 24.0);
    });

    testWidgets('debe incluir Semantics label para accesibilidad', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CatLoadingIndicator.general())),
      );

      expect(find.bySemanticsLabel('Cargando...'), findsOneWidget);
    });
  });
}
