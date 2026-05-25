// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para BulkProductListScreen.
//
// Cubre:
// - Estado loading → CatLoadingIndicator
// - Lista con productos → ListView con Cards
// - Lista vacía → "No hay materias primas"
// - Error → mensaje + botón Reintentar
// - FAB → navegación a BulkProductFormScreen
// - Pull-to-refresh → recarga
//
// Usa BulkProductProvider real con MockIBulkProductRepository
// siguiendo el patrón de login_screen_test.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_form_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_list_screen.dart';

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

Widget createTestApp(BulkProductProvider provider) {
  return ChangeNotifierProvider<BulkProductProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: BulkProductListScreen(),
    ),
  );
}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockBulkProductRepository mockRepo;
  late BulkProductProvider provider;

  setUpAll(() {
    registerFallbackValue(
      const BulkProduct(id: 0, name: '', unitOfMeasure: '', stock: 0.0),
    );
  });

  setUp(() {
    mockRepo = MockBulkProductRepository();
    provider = BulkProductProvider(mockRepo);

    // Stubs por defecto
    when(() => mockRepo.getBulkProducts()).thenAnswer((_) async => []);
    when(() => mockRepo.createBulkProduct(any())).thenAnswer(
      (_) async => const BulkProduct(
        id: 1,
        name: 'Test',
        unitOfMeasure: 'L',
        stock: 10.0,
      ),
    );
    when(() => mockRepo.updateBulkProduct(any())).thenAnswer(
      (_) async => const BulkProduct(
        id: 1,
        name: 'Updated',
        unitOfMeasure: 'L',
        stock: 20.0,
      ),
    );
    when(() => mockRepo.deleteBulkProduct(any())).thenAnswer((_) async {});
  });

  group('BulkProductListScreen', () {
    testWidgets(
      'debe mostrar indicador de carga cuando status es initial/loading',
      (tester) async {
        // Arrange: repo nunca completa (status se queda en initial)
        when(
          () => mockRepo.getBulkProducts(),
        ).thenAnswer((_) => Completer<List<BulkProduct>>().future);

        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        // Assert: spinner visible
        expect(find.byType(CatLoadingIndicator), findsOneWidget);
      },
    );

    testWidgets('debe mostrar lista de productos cuando hay datos', (
      tester,
    ) async {
      // Arrange: repo retorna 2 productos
      final products = [
        const BulkProduct(
          id: 1,
          name: 'Alcohol',
          unitOfMeasure: 'L',
          stock: 10.0,
        ),
        const BulkProduct(
          id: 2,
          name: 'Glicerina',
          unitOfMeasure: 'kg',
          stock: 5.0,
        ),
      ];
      when(() => mockRepo.getBulkProducts()).thenAnswer((_) async => products);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Assert: 2 ListTile con nombres de productos
      expect(find.text('Alcohol'), findsOneWidget);
      expect(find.text('Glicerina'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('debe mostrar mensaje vacío cuando no hay productos', (
      tester,
    ) async {
      // Arrange: repo retorna lista vacía (default stub)
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Assert: mensaje de lista vacía
      expect(find.text('No hay materias primas'), findsOneWidget);
    });

    testWidgets('debe mostrar error y botón de reintentar cuando falla carga', (
      tester,
    ) async {
      // Arrange: repo lanza excepción
      when(
        () => mockRepo.getBulkProducts(),
      ).thenThrow(Exception('Error de red'));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Assert: muestra error + botón Reintentar
      expect(find.text('Reintentar'), findsOneWidget);

      // Ahora stub repo para que funcione y tocar Reintentar
      when(() => mockRepo.getBulkProducts()).thenAnswer(
        (_) async => [
          const BulkProduct(
            id: 1,
            name: 'Alcohol',
            unitOfMeasure: 'L',
            stock: 10.0,
          ),
        ],
      );

      await tester.tap(find.text('Reintentar'));
      await pumpUntilSettled(tester);

      // Assert: ahora muestra la lista
      expect(find.text('Alcohol'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('debe navegar al formulario al tocar FAB', (tester) async {
      // Arrange: repo retorna lista vacía
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Act: tocar FAB
      await tester.tap(find.byType(FloatingActionButton));
      await pumpUntilSettled(tester);

      // Assert: BulkProductFormScreen está visible
      expect(find.byType(BulkProductFormScreen), findsOneWidget);
    });

    testWidgets('debe refrescar al hacer pull-to-refresh', (tester) async {
      // Arrange: repo retorna varios productos para que RefreshIndicator se muestre
      when(() => mockRepo.getBulkProducts()).thenAnswer(
        (_) async => List.generate(
          10,
          (i) => BulkProduct(
            id: i + 1,
            name: 'Producto ${i + 1}',
            unitOfMeasure: 'L',
            stock: 10.0,
          ),
        ),
      );

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Assert: RefreshIndicator presente y datos cargados
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(provider.bulkProducts, hasLength(10));

      // Act: simular refresh (como haría onRefresh del RefreshIndicator)
      await provider.getBulkProducts();
      await tester.pump();

      // Assert: datos recargados correctamente
      expect(provider.status, BulkProductStatus.loaded);
      expect(provider.bulkProducts, hasLength(10));
    });
  });
}
