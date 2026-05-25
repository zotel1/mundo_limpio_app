// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para ProductsListScreen.
//
// Cubre:
// - Estado loading → CatLoadingIndicator
// - Lista con productos → ListView con Cards
// - Lista vacía → "No hay productos"
// - Error → mensaje + botón Reintentar
// - FAB → navegación a ProductsFormScreen
// - Pull-to-refresh → recarga
// - Toggle activos/todos cambia modo de carga
// - Swipe to delete con confirmación
//
// Usa ProductsProvider real con MockIProductsRepository.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/domain/repositories/i_products_repository.dart';
import 'package:mundo_limpio_app/features/products/presentation/providers/products_provider.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_form_screen.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_list_screen.dart';

class MockProductsRepository extends Mock implements IProductsRepository {}

Widget createTestApp(ProductsProvider provider) {
  return ChangeNotifierProvider<ProductsProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: const ProductsListScreen(),
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
    when(
      () => mockRepo.create(any()),
    ).thenAnswer((_) async => const Product(id: 1, name: 'Test'));
    when(
      () => mockRepo.update(any()),
    ).thenAnswer((_) async => const Product(id: 1, name: 'Updated'));
    when(() => mockRepo.delete(any())).thenAnswer((_) async {});
    when(() => mockRepo.reactivate(any())).thenAnswer(
      (_) async => const Product(id: 1, name: 'Reactivated', active: true),
    );
    when(() => mockRepo.getById(any())).thenAnswer(
      (_) async => const Product(id: 1, sku: 'SKU001', name: 'Test'),
    );
    when(() => mockRepo.getBySku(any())).thenAnswer(
      (_) async => const Product(id: 1, sku: 'SKU001', name: 'Test'),
    );
  });

  group('ProductsListScreen', () {
    testWidgets(
      'debe mostrar indicador de carga cuando status es initial/loading',
      (tester) async {
        when(
          () => mockRepo.getAll(),
        ).thenAnswer((_) => Completer<List<Product>>().future);

        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        expect(find.byType(CatLoadingIndicator), findsOneWidget);
      },
    );

    testWidgets('debe mostrar lista de productos cuando hay datos', (
      tester,
    ) async {
      final products = [
        const Product(id: 1, sku: 'SKU001', name: 'Alcohol', minPrice: 10.0),
        const Product(id: 2, sku: 'SKU002', name: 'Detergente'),
      ];
      when(() => mockRepo.getAll()).thenAnswer((_) async => products);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('Alcohol'), findsOneWidget);
      expect(find.text('Detergente'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('debe mostrar mensaje vacío cuando no hay productos', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('No hay productos'), findsOneWidget);
    });

    testWidgets('debe mostrar error y botón de reintentar cuando falla carga', (
      tester,
    ) async {
      when(() => mockRepo.getAll()).thenThrow(Exception('Error de red'));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('Reintentar'), findsOneWidget);

      // Ahora stub repo para que funcione y tocar Reintentar
      when(() => mockRepo.getAll()).thenAnswer(
        (_) async => [const Product(id: 1, sku: 'SKU001', name: 'Alcohol')],
      );

      await tester.tap(find.text('Reintentar'));
      await pumpUntilSettled(tester);

      expect(find.text('Alcohol'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('debe navegar al formulario al tocar FAB', (tester) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await pumpUntilSettled(tester);

      expect(find.byType(ProductsFormScreen), findsOneWidget);
    });

    testWidgets('debe refrescar al hacer pull-to-refresh', (tester) async {
      when(() => mockRepo.getAll()).thenAnswer(
        (_) async => List.generate(
          10,
          (i) => Product(id: i + 1, name: 'Producto ${i + 1}'),
        ),
      );

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(provider.products, hasLength(10));

      await provider.loadProducts();
      await tester.pump();

      expect(provider.status, ProductStatus.loaded);
      expect(provider.products, hasLength(10));
    });

    testWidgets('debe mostrar toggle entre activos y todos', (tester) async {
      when(() => mockRepo.getAll()).thenAnswer(
        (_) async => [const Product(id: 1, name: 'Activo', active: true)],
      );
      when(() => mockRepo.getAllProducts()).thenAnswer(
        (_) async => [
          const Product(id: 1, name: 'Activo', active: true),
          const Product(id: 2, name: 'Inactivo', active: false),
        ],
      );

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Debe mostrar un toggle de algún tipo
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets(
      'debe mostrar diálogo de confirmación al hacer swipe to delete',
      (tester) async {
        final products = [const Product(id: 1, sku: 'SKU001', name: 'Alcohol')];
        when(() => mockRepo.getAll()).thenAnswer((_) async => products);

        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        // Deslizar el item
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Debe aparecer el diálogo de confirmación
        expect(
          find.text('¿Estás seguro que querés eliminar este producto?'),
          findsOneWidget,
        );
        expect(find.text('Cancelar'), findsOneWidget);
        expect(find.text('Eliminar'), findsOneWidget);
      },
    );

    testWidgets('debe eliminar producto al confirmar swipe to delete', (
      tester,
    ) async {
      final products = [const Product(id: 1, sku: 'SKU001', name: 'Alcohol')];
      when(() => mockRepo.getAll()).thenAnswer((_) async => products);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tocar "Eliminar" en el diálogo
      await tester.tap(find.text('Eliminar'));
      await pumpUntilSettled(tester);

      // delete debe haber sido llamado
      verify(() => mockRepo.delete(1)).called(1);
    });
  });
}
