// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para ProductionBatchListScreen.
//
// Cubre:
// - Estado loading → CatLoadingIndicator
// - Lista con lotes → Cards con Lote #1 y Lote #2
// - Lista vacía → "No hay lotes de producción"
// - Error → mensaje + botón Reintentar
// - FAB → navegación a ProductionCreateScreen
//
// Usa ProductionProvider y BulkProductProvider reales con mocks
// de repositorio, ya que ProductionCreateScreen necesita ambos providers.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/production_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_batch_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_create_screen.dart';

class MockProductionRepository extends Mock implements IProductionRepository {}

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

Widget createTestApp(
  ProductionProvider prodProvider,
  BulkProductProvider bpProvider,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProductionProvider>.value(value: prodProvider),
      ChangeNotifierProvider<BulkProductProvider>.value(value: bpProvider),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: ProductionBatchListScreen(),
    ),
  );
}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockProductionRepository mockProdRepo;
  late MockBulkProductRepository mockBulkRepo;
  late ProductionProvider prodProvider;
  late BulkProductProvider bpProvider;

  setUpAll(() {
    registerFallbackValue(
      const BulkProduct(
        id: 0,
        name: '',
        currentStockLiters: 0,
        costPerLiter: 0,
      ),
    );
    registerFallbackValue(
      ProductionBatchRequest(
        finishedProductId: 0,
        bulkProductId: 0,
        quantityUsed: 0.0,
      ),
    );
    registerFallbackValue(
      ProductionBatch(
        id: 0,
        productId: 0,
        bulkProductId: 0,
        initialQuantity: 0.0,
        currentStock: 0.0,
        unitCostAtProduction: 0.0,
        rawQuantityUsed: 0.0,
        productionDate: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockProdRepo = MockProductionRepository();
    mockBulkRepo = MockBulkProductRepository();
    prodProvider = ProductionProvider(mockProdRepo, mockBulkRepo);
    bpProvider = BulkProductProvider(mockBulkRepo);

    // Stubs por defecto para ProductionRepository
    when(() => mockProdRepo.getProductionBatches()).thenAnswer(
      (_) async => [
        ProductionBatch(
          id: 1,
          productId: 10,
          productName: 'Jabón Líquido',
          bulkProductId: 1,
          bulkProductName: 'Alcohol',
          initialQuantity: 100.0,
          currentStock: 85.0,
          unitCostAtProduction: 12.5,
          rawQuantityUsed: 15.0,
          productionDate: DateTime(2026, 5, 18),
        ),
        ProductionBatch(
          id: 2,
          productId: 10,
          productName: 'Jabón Líquido',
          bulkProductId: 2,
          bulkProductName: 'Esencia',
          initialQuantity: 50.0,
          currentStock: 40.0,
          unitCostAtProduction: 10.0,
          rawQuantityUsed: 10.0,
          productionDate: DateTime(2026, 5, 17),
        ),
      ],
    );

    // Stubs por defecto para BulkProductRepository (necesario para CreateScreen)
    when(() => mockBulkRepo.getBulkProducts()).thenAnswer((_) async => []);
    when(() => mockBulkRepo.createBulkProduct(any())).thenAnswer(
      (_) async => const BulkProduct(
        id: 1,
        name: 'Test',
        currentStockLiters: 10.0,
        costPerLiter: 5.0,
      ),
    );
    when(() => mockBulkRepo.updateBulkProduct(any())).thenAnswer(
      (_) async => const BulkProduct(
        id: 1,
        name: 'Updated',
        currentStockLiters: 20.0,
        costPerLiter: 6.0,
      ),
    );
    when(() => mockBulkRepo.deleteBulkProduct(any())).thenAnswer((_) async {});
    when(() => mockBulkRepo.getBulkProduct(any())).thenAnswer(
      (_) async => const BulkProduct(
        id: 1,
        name: 'Alcohol',
        currentStockLiters: 100.0,
        costPerLiter: 10.0,
      ),
    );
  });

  group('ProductionBatchListScreen', () {
    testWidgets('debe mostrar indicador de carga al iniciar', (tester) async {
      // Arrange: repo nunca completa (status se queda en initial)
      when(
        () => mockProdRepo.getProductionBatches(),
      ).thenAnswer((_) => Completer<List<ProductionBatch>>().future);

      await tester.pumpWidget(createTestApp(prodProvider, bpProvider));
      await pumpUntilSettled(tester);

      // Assert: spinner visible
      expect(find.byType(CatLoadingIndicator), findsOneWidget);
    });

    testWidgets('debe mostrar lista de lotes cuando hay datos', (tester) async {
      await tester.pumpWidget(createTestApp(prodProvider, bpProvider));
      await pumpUntilSettled(tester);

      // Assert: títulos de lote visibles
      expect(find.text('Lote #1'), findsOneWidget);
      expect(find.text('Lote #2'), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje vacío cuando no hay lotes', (
      tester,
    ) async {
      // Arrange: repo retorna lista vacía
      when(
        () => mockProdRepo.getProductionBatches(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestApp(prodProvider, bpProvider));
      await pumpUntilSettled(tester);

      // Assert: mensaje de lista vacía
      expect(find.text('No hay lotes de producción'), findsOneWidget);
    });

    testWidgets('debe mostrar error y botón reintentar', (tester) async {
      // Arrange: repo lanza excepción
      when(
        () => mockProdRepo.getProductionBatches(),
      ).thenThrow(Exception('Error de red'));

      await tester.pumpWidget(createTestApp(prodProvider, bpProvider));
      await pumpUntilSettled(tester);

      // Assert: botón Reintentar visible
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('debe navegar a creación al tocar FAB', (tester) async {
      await tester.pumpWidget(createTestApp(prodProvider, bpProvider));
      await pumpUntilSettled(tester);

      // Act: tocar FAB
      await tester.tap(find.byType(FloatingActionButton));
      await pumpUntilSettled(tester);

      // Assert: ProductionCreateScreen visible
      expect(find.byType(ProductionCreateScreen), findsOneWidget);
    });
  });
}
