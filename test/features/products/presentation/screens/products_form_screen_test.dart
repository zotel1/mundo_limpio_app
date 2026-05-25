// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para ProductsFormScreen.
//
// Cubre:
// - CREATE mode: AppBar, campos, validación, submit exitoso, error
// - EDIT mode: AppBar, pre-filled values, update submit
//
// Usa ProductsProvider real con MockIProductsRepository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/domain/repositories/i_products_repository.dart';
import 'package:mundo_limpio_app/features/products/presentation/providers/products_provider.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_form_screen.dart';

class MockProductsRepository extends Mock implements IProductsRepository {}

Widget createTestApp(ProductsProvider provider, {Product? product}) {
  return ChangeNotifierProvider<ProductsProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: ProductsFormScreen(product: product),
    ),
  );
}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockProductsRepository mockRepo;
  late ProductsProvider provider;

  setUpAll(() {
    registerFallbackValue(const Product(id: 0, name: ''));
  });

  setUp(() {
    mockRepo = MockProductsRepository();
    provider = ProductsProvider(mockRepo);

    // Stubs por defecto
    when(() => mockRepo.getAll()).thenAnswer((_) async => []);
    when(() => mockRepo.getAllProducts()).thenAnswer((_) async => []);
    when(() => mockRepo.create(any())).thenAnswer(
      (_) async => const Product(id: 1, sku: 'SKU001', name: 'Test'),
    );
    when(() => mockRepo.update(any())).thenAnswer(
      (_) async => const Product(id: 1, sku: 'SKU001', name: 'Updated'),
    );
    when(() => mockRepo.delete(any())).thenAnswer((_) async {});
    when(() => mockRepo.reactivate(any())).thenAnswer(
      (_) async => const Product(id: 1, name: 'Reactivated', active: true),
    );
    when(() => mockRepo.getById(any())).thenAnswer(
      (_) async => const Product(id: 1, sku: 'SKU001', name: 'Test'),
    );
  });

  group('ProductsFormScreen — create mode', () {
    testWidgets('debe mostrar "Nuevo Producto" en el AppBar', (tester) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('Nuevo Producto'), findsOneWidget);
    });

    testWidgets('debe mostrar campos de SKU, nombre y precio mínimo', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // 3 campos en create mode: SKU, nombre, precio mínimo
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
        expect(find.text('El SKU es requerido'), findsOneWidget);
        expect(find.text('El nombre es requerido'), findsOneWidget);
      },
    );

    testWidgets('debe validar que minPrice sea un número positivo', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Llenar solo campos obligatorios y poner precio inválido
      await tester.enterText(find.byType(TextFormField).at(0), 'SKU001');
      await tester.enterText(find.byType(TextFormField).at(1), 'Alcohol');
      await tester.enterText(find.byType(TextFormField).at(2), '-5');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await pumpUntilSettled(tester);

      expect(find.text('Debe ser un número positivo'), findsOneWidget);
    });

    testWidgets(
      'debe crear producto y navegar hacia atrás al guardar con datos válidos',
      (tester) async {
        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        // Act: llenar campos
        await tester.enterText(find.byType(TextFormField).at(0), 'SKU001');
        await tester.enterText(find.byType(TextFormField).at(1), 'Alcohol');
        await tester.enterText(find.byType(TextFormField).at(2), '10.50');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
        await pumpUntilSettled(tester);

        // Assert: create fue llamado
        verify(() => mockRepo.create(any())).called(1);
        // Assert: la pantalla se cerró (pop ocurrió)
        expect(find.byType(ProductsFormScreen), findsNothing);
      },
    );

    testWidgets('debe mostrar SnackBar si create falla', (tester) async {
      when(() => mockRepo.create(any())).thenThrow(Exception('Error al crear'));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'SKU001');
      await tester.enterText(find.byType(TextFormField).at(1), 'Alcohol');
      await tester.enterText(find.byType(TextFormField).at(2), '10.0');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await pumpUntilSettled(tester);

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('ProductsFormScreen — edit mode', () {
    final editProduct = const Product(
      id: 1,
      sku: 'SKU001',
      name: 'Alcohol',
      minPrice: 10.50,
    );

    testWidgets('debe mostrar "Editar Producto" en el AppBar', (tester) async {
      await tester.pumpWidget(createTestApp(provider, product: editProduct));
      await pumpUntilSettled(tester);

      expect(find.text('Editar Producto'), findsOneWidget);
    });

    testWidgets('debe pre-llenar los campos con los valores del producto', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider, product: editProduct));
      await pumpUntilSettled(tester);

      // 3 campos en edit mode también
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Los campos deben tener los valores pre-cargados
      expect(find.text('SKU001'), findsOneWidget);
      expect(find.text('Alcohol'), findsOneWidget);
      expect(find.text('10.50'), findsOneWidget);
    });

    testWidgets('debe llamar update al guardar cambios', (tester) async {
      await tester.pumpWidget(createTestApp(provider, product: editProduct));
      await pumpUntilSettled(tester);

      // Modificar nombre y guardar
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Alcohol Modificado',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await pumpUntilSettled(tester);

      verify(() => mockRepo.update(any())).called(1);
      expect(find.byType(ProductsFormScreen), findsNothing);
    });
  });
}
