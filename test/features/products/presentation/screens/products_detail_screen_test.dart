// TDD: RED — test escrito antes que la implementación
//
// Pruebas de widget para ProductsDetailScreen.
//
// Cubre:
// - Estado loading → CatLoadingIndicator
// - Muestra todos los campos del producto
// - Botón de editar → navega a ProductsFormScreen
// - Botón de eliminar → confirmación → elimina y vuelve
// - Botón de reactivar (si inactivo) → confirmación → reactiva
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
import 'package:mundo_limpio_app/features/products/presentation/screens/products_detail_screen.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_form_screen.dart';

class MockProductsRepository extends Mock implements IProductsRepository {}

Widget createTestApp(ProductsProvider provider, int productId) {
  return ChangeNotifierProvider<ProductsProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: ProductsDetailScreen(productId: productId),
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
  });

  group('ProductsDetailScreen', () {
    testWidgets(
      'debe mostrar indicador de carga cuando status es initial/loading',
      (tester) async {
        // Usar Completer para que la future nunca se resuelva
        final completer = Completer<Product>();
        when(() => mockRepo.getById(any())).thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestApp(provider, 1));
        await pumpUntilSettled(tester);

        expect(find.byType(CatLoadingIndicator), findsOneWidget);
      },
    );

    testWidgets('debe mostrar todos los campos del producto activo', (
      tester,
    ) async {
      const product = Product(
        id: 1,
        sku: 'SKU001',
        name: 'Alcohol',
        minPrice: 10.50,
        active: true,
      );
      when(() => mockRepo.getById(1)).thenAnswer((_) async => product);

      await tester.pumpWidget(createTestApp(provider, 1));
      await pumpUntilSettled(tester);

      // Debe mostrar los campos
      expect(find.text('1'), findsOneWidget); // ID
      expect(find.text('SKU001'), findsOneWidget); // SKU
      expect(find.text('Alcohol'), findsOneWidget); // Nombre
      expect(find.text('10.50'), findsOneWidget); // Precio Mínimo
      expect(find.text('Activo'), findsOneWidget); // Estado
    });

    testWidgets('debe mostrar botón de editar y navegar al formulario', (
      tester,
    ) async {
      const product = Product(
        id: 1,
        sku: 'SKU001',
        name: 'Alcohol',
        active: true,
      );
      when(() => mockRepo.getById(1)).thenAnswer((_) async => product);

      await tester.pumpWidget(createTestApp(provider, 1));
      await pumpUntilSettled(tester);

      // Tocar botón de editar (icono de edit)
      await tester.tap(find.byIcon(Icons.edit));
      await pumpUntilSettled(tester);

      // Debe navegar a ProductsFormScreen
      expect(find.byType(ProductsFormScreen), findsOneWidget);
    });

    testWidgets('debe mostrar botón eliminar para producto activo', (
      tester,
    ) async {
      const product = Product(
        id: 1,
        sku: 'SKU001',
        name: 'Alcohol',
        active: true,
      );
      when(() => mockRepo.getById(1)).thenAnswer((_) async => product);

      await tester.pumpWidget(createTestApp(provider, 1));
      await pumpUntilSettled(tester);

      // Debe haber icono de eliminar (delete)
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('debe confirmar y eliminar producto', (tester) async {
      const product = Product(
        id: 1,
        sku: 'SKU001',
        name: 'Alcohol',
        active: true,
      );
      when(() => mockRepo.getById(1)).thenAnswer((_) async => product);
      when(() => mockRepo.delete(1)).thenAnswer((_) async {});

      await tester.pumpWidget(createTestApp(provider, 1));
      await pumpUntilSettled(tester);

      // Tocar eliminar
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirmar en diálogo
      expect(find.text('Eliminar'), findsWidgets);
      // Tocar el botón Eliminar del diálogo
      await tester.tap(find.text('Eliminar').last);
      await pumpUntilSettled(tester);

      verify(() => mockRepo.delete(1)).called(1);
    });

    testWidgets('debe mostrar botón reactivar para producto inactivo', (
      tester,
    ) async {
      const product = Product(
        id: 2,
        sku: 'SKU002',
        name: 'Inactivo',
        active: false,
      );
      when(() => mockRepo.getById(2)).thenAnswer((_) async => product);

      await tester.pumpWidget(createTestApp(provider, 2));
      await pumpUntilSettled(tester);

      // No debe mostrar delete, debe mostrar reactivar (refresh icon)
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('debe confirmar y reactivar producto inactivo', (tester) async {
      const product = Product(
        id: 2,
        sku: 'SKU002',
        name: 'Inactivo',
        active: false,
      );
      const reactivated = Product(
        id: 2,
        sku: 'SKU002',
        name: 'Inactivo',
        active: true,
      );
      when(() => mockRepo.getById(2)).thenAnswer((_) async => product);
      when(() => mockRepo.reactivate(2)).thenAnswer((_) async => reactivated);

      await tester.pumpWidget(createTestApp(provider, 2));
      await pumpUntilSettled(tester);

      // Tocar reactivar
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirmar en diálogo
      expect(find.text('Reactivar'), findsWidgets);
      // Tocar el botón Reactivar del diálogo
      await tester.tap(find.text('Reactivar').last);
      await pumpUntilSettled(tester);

      verify(() => mockRepo.reactivate(2)).called(1);
    });
  });
}
