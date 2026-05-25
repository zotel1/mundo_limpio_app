// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para BulkProductFormScreen.
//
// Cubre:
// - CREATE mode: AppBar, campos, validación, submit exitoso, error
// - EDIT mode: AppBar, pre-filled values, update submit
//
// Usa BulkProductProvider real con MockIBulkProductRepository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_form_screen.dart';

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

Widget createTestApp(BulkProductProvider provider, {BulkProduct? product}) {
  return ChangeNotifierProvider<BulkProductProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: BulkProductFormScreen(product: product),
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

  group('BulkProductFormScreen — create mode', () {
    testWidgets('debe mostrar "Nueva Materia Prima" en el AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('Nueva Materia Prima'), findsOneWidget);
    });

    testWidgets('debe mostrar campos de nombre, unidad de medida y stock', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // 3 campos en create mode: nombre, unidad de medida, stock
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets(
      'debe mostrar error de validación al guardar con campos vacíos',
      (tester) async {
        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        // Act: tocar Guardar sin llenar campos
        await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
        await pumpUntilSettled(tester);

        // Assert: mensajes de validación visibles
        expect(find.text('El nombre es requerido'), findsOneWidget);
      },
    );

    testWidgets(
      'debe crear producto y navegar hacia atrás al guardar con datos válidos',
      (tester) async {
        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        // Act: llenar campos
        await tester.enterText(find.byType(TextFormField).at(0), 'Alcohol');
        await tester.enterText(find.byType(TextFormField).at(1), 'L');
        await tester.enterText(find.byType(TextFormField).at(2), '10.0');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
        await pumpUntilSettled(tester);

        // Assert: createBulkProduct fue llamado
        verify(() => mockRepo.createBulkProduct(any())).called(1);
        // Assert: la pantalla se cerró (pop ocurrió)
        expect(find.byType(BulkProductFormScreen), findsNothing);
      },
    );

    testWidgets('debe mostrar SnackBar si createBulkProduct falla', (
      tester,
    ) async {
      // Arrange: createBulkProduct lanza excepción
      when(
        () => mockRepo.createBulkProduct(any()),
      ).thenThrow(Exception('Error al crear'));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Act: llenar campos y guardar
      await tester.enterText(find.byType(TextFormField).at(0), 'Alcohol');
      await tester.enterText(find.byType(TextFormField).at(1), 'L');
      await tester.enterText(find.byType(TextFormField).at(2), '10.0');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await pumpUntilSettled(tester);

      // Assert: SnackBar visible con mensaje de error
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('BulkProductFormScreen — edit mode', () {
    final editProduct = const BulkProduct(
      id: 1,
      name: 'Alcohol',
      unitOfMeasure: 'L',
      stock: 100.0,
    );

    testWidgets('debe mostrar "Editar Materia Prima" en el AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider, product: editProduct));
      await pumpUntilSettled(tester);

      expect(find.text('Editar Materia Prima'), findsOneWidget);
    });

    testWidgets('debe pre-llenar los campos con los valores del producto', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider, product: editProduct));
      await pumpUntilSettled(tester);

      // Solo 2 campos en edit mode (sin stock)
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Los campos deben tener los valores pre-cargados
      expect(find.text('Alcohol'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('debe llamar updateBulkProduct al guardar cambios', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider, product: editProduct));
      await pumpUntilSettled(tester);

      // Act: modificar nombre y guardar
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Alcohol Modificado',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await pumpUntilSettled(tester);

      // Assert: updateBulkProduct llamado
      verify(() => mockRepo.updateBulkProduct(any())).called(1);
      // Assert: la pantalla se cerró
      expect(find.byType(BulkProductFormScreen), findsNothing);
    });
  });
}
