// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para ProductionCreateScreen.
//
// Cubre:
// - Renderizado del formulario (AppBar, 4 campos)
// - Dropdown de materias primas cargado desde BulkProductProvider
// - Validación al enviar vacío
// - Creación exitosa de batch
// - SnackBar de error
//
// Usa BulkProductProvider y ProductionProvider reales con mocks
// de repositorio, siguiendo el patrón de login_screen_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/production_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_create_screen.dart';

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

class MockProductionRepository extends Mock implements IProductionRepository {}

class MockAuthProvider extends Mock implements AuthProvider {}

Widget createTestApp(
  BulkProductProvider bpProvider,
  ProductionProvider prodProvider,
) {
  final auth = MockAuthProvider();
  when(() => auth.roles).thenReturn(['PRODUCTION_OP']);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BulkProductProvider>.value(value: bpProvider),
      ChangeNotifierProvider<ProductionProvider>.value(value: prodProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: ProductionCreateScreen(),
    ),
  );
}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockBulkProductRepository mockBulkRepo;
  late MockProductionRepository mockProdRepo;
  late BulkProductProvider bpProvider;
  late ProductionProvider prodProvider;

  setUpAll(() {
    registerFallbackValue(
      const BulkProduct(
        id: 0,
        name: '',
        currentStockLiters: 0,
        costPerLiter: 0,
        conversionRatio: 1.0,
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
    mockBulkRepo = MockBulkProductRepository();
    mockProdRepo = MockProductionRepository();
    bpProvider = BulkProductProvider(mockBulkRepo);
    prodProvider = ProductionProvider(mockProdRepo, mockBulkRepo);

    // Stubs por defecto
    when(() => mockBulkRepo.getBulkProducts()).thenAnswer(
      (_) async => [
        const BulkProduct(
          id: 1,
          name: 'Alcohol',
          currentStockLiters: 100,
          costPerLiter: 10.0,
          conversionRatio: 1.0,
        ),
        const BulkProduct(
          id: 2,
          name: 'Esencia',
          currentStockLiters: 50,
          costPerLiter: 8.0,
          conversionRatio: 1.0,
        ),
      ],
    );
    when(() => mockProdRepo.createProductionBatch(any())).thenAnswer(
      (_) async => ProductionBatch(
        id: 1,
        productId: 10,
        bulkProductId: 1,
        initialQuantity: 5.0,
        currentStock: 4.0,
        unitCostAtProduction: 10.0,
        rawQuantityUsed: 5.0,
        productionDate: DateTime.now(),
      ),
    );
    when(() => mockBulkRepo.getBulkProduct(any())).thenAnswer(
      (_) async => const BulkProduct(
        id: 1,
        name: 'Alcohol',
        currentStockLiters: 100.0,
        costPerLiter: 10.0,
        conversionRatio: 1.0,
      ),
    );
  });

  group('ProductionCreateScreen', () {
    testWidgets('debe mostrar el formulario de creación', (tester) async {
      await tester.pumpWidget(createTestApp(bpProvider, prodProvider));
      await pumpUntilSettled(tester);

      // AppBar title
      expect(find.text('Nueva Producción'), findsOneWidget);
      // 4 form fields: finishedProductId, dropdown, quantityUsed, quantityProduced
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });

    testWidgets('debe cargar las materias primas en el dropdown', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(bpProvider, prodProvider));
      await pumpUntilSettled(tester);

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await pumpUntilSettled(tester);

      // Items should be visible in the overlay
      expect(find.text('Alcohol'), findsWidgets);
      expect(find.text('Esencia'), findsWidgets);
    });

    testWidgets('debe mostrar errores de validación al enviar vacío', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(bpProvider, prodProvider));
      await pumpUntilSettled(tester);

      // Scroll down y tap guardar sin llenar campos
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Guardar'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await pumpUntilSettled(tester);

      // Validation messages should appear
      expect(find.text('El ID del producto es requerido'), findsOneWidget);
      expect(find.text('Seleccione una materia prima'), findsOneWidget);
      // Two quantity fields (used + produced) — both show "requerida" when empty
      expect(find.text('La cantidad es requerida'), findsAtLeast(1));
    });

    testWidgets('debe crear un batch exitosamente', (tester) async {
      await tester.pumpWidget(createTestApp(bpProvider, prodProvider));
      await pumpUntilSettled(tester);

      // Fill finishedProductId
      await tester.enterText(find.byType(TextFormField).at(0), '10');

      // Open dropdown and select first item
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await pumpUntilSettled(tester);
      await tester.tap(find.text('Alcohol').last);
      await pumpUntilSettled(tester);

      // Fill quantityUsed
      await tester.enterText(find.byType(TextFormField).at(1), '5.0');

      // Fill quantityProduced
      await tester.enterText(find.byType(TextFormField).at(2), '4.0');

      // Tap guardar
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Guardar'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await pumpUntilSettled(tester);

      // Verify repo was called
      verify(() => mockProdRepo.createProductionBatch(any())).called(1);
      // Screen should have popped
      expect(find.byType(ProductionCreateScreen), findsNothing);
    });

    testWidgets('debe mostrar SnackBar en caso de error', (tester) async {
      // Arrange: repo throws
      when(
        () => mockProdRepo.createProductionBatch(any()),
      ).thenThrow(Exception('Error de conexión'));

      await tester.pumpWidget(createTestApp(bpProvider, prodProvider));
      await pumpUntilSettled(tester);

      // Fill finishedProductId
      await tester.enterText(find.byType(TextFormField).at(0), '10');

      // Open dropdown and select first item
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await pumpUntilSettled(tester);
      await tester.tap(find.text('Alcohol').last);
      await pumpUntilSettled(tester);

      // Fill quantityUsed
      await tester.enterText(find.byType(TextFormField).at(1), '5.0');

      // Fill quantityProduced
      await tester.enterText(find.byType(TextFormField).at(2), '4.0');

      // Tap guardar
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Guardar'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await pumpUntilSettled(tester);

      // Assert: SnackBar visible with error
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
