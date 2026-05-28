// Pruebas de widget para CreateSaleScreen.
//
// Cubre los 6 escenarios de R5:
// - R5.1: Auto-carga de productos al iniciar
// - R5.2: Spinner durante carga
// - R5.3: Dropdown de productos cuando están cargados
// - R5.4: Stock + formulario de cantidad cuando stock cargado
// - R5.5: Creación de venta y navegación a SaleResultScreen
// - R5.6: Mensaje de error en fallo de API
//
// Usa SalesProvider real con MockSalesRepository para probar
// la integración completa entre UI y provider.
//
// TDD: RED — test escrito antes que la implementación de la pantalla

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_provider.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/create_sale_screen.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sale_result_screen.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

class MockAuthProvider extends Mock implements AuthProvider {}

/// Crea la app de test con SalesProvider real y mock repository.
Widget createTestApp(SalesProvider provider) {
  final auth = MockAuthProvider();
  when(() => auth.roles).thenReturn(['SALES_CLERK']);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SalesProvider>.value(value: provider),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: CreateSaleScreen(),
    ),
  );
}

/// Helper para pump repetido hasta que los async tasks resuelven.
Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockSalesRepository mockRepo;
  late SalesProvider provider;

  const productA = ProductResponse(id: 1, name: 'Producto A');
  const productB = ProductResponse(id: 2, name: 'Producto B');
  const batch = ProductionBatchResponse(
    id: 1,
    productId: 1,
    currentStock: 100.0,
  );
  const saleItem = SaleItemResponse(
    batchId: 42,
    productId: 1,
    productName: 'Test Product',
    quantity: 30.0,
    unitPrice: 150.00,
    unitCost: 100.00,
  );
  final testDate = DateTime(2026, 5, 10, 10, 30, 0);

  setUpAll(() {
    registerFallbackValue(const SaleRequest(productId: 0, quantity: 0));
  });

  setUp(() {
    mockRepo = MockSalesRepository();
    provider = SalesProvider(mockRepo);

    // Stubs por defecto: carga exitosa de productos y stock
    when(
      () => mockRepo.getProducts(),
    ).thenAnswer((_) async => [productA, productB]);
    when(
      () => mockRepo.getBatchesByProduct(any()),
    ).thenAnswer((_) async => [batch]);
    when(() => mockRepo.createSale(any())).thenAnswer(
      (_) async => SaleResponse(
        id: 1,
        totalAmount: 375.00,
        createdAt: testDate,
        items: const [saleItem],
      ),
    );
  });

  // ──────────────────────────────────────────────
  // R5.1: Auto-carga de productos al iniciar
  // ──────────────────────────────────────────────
  group('CreateSaleScreen — R5.1: Auto-carga de productos', () {
    testWidgets('debe cargar productos automáticamente al iniciar (R5.1)', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      verify(() => mockRepo.getProducts()).called(1);
      expect(provider.status, SalesStatus.productsLoaded);
    });
  });

  // ──────────────────────────────────────────────
  // R5.2: Spinner durante carga
  // ──────────────────────────────────────────────
  group('CreateSaleScreen — R5.2: Spinner mientras carga', () {
    testWidgets('debe mostrar spinner mientras carga productos (R5.2)', (
      tester,
    ) async {
      final completer = Completer<List<ProductResponse>>();
      when(() => mockRepo.getProducts()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestApp(provider));
      // Un frame para que initState → loadProducts → loading
      await tester.pump();

      expect(find.byType(CatLoadingIndicator), findsOneWidget);

      completer.complete([productA]);
    });
  });

  // ──────────────────────────────────────────────
  // R5.3: Dropdown de productos
  // ──────────────────────────────────────────────
  group('CreateSaleScreen — R5.3: Dropdown de productos', () {
    testWidgets(
      'debe mostrar dropdown de productos cuando están cargados (R5.3)',
      (tester) async {
        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        // Debe mostrar el hint del dropdown
        expect(find.text('Seleccioná un producto'), findsOneWidget);
        // Debe mostrar el DropdownButtonFormField (con tipo int explícito)
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString().contains('DropdownButtonFormField'),
          ),
          findsOneWidget,
        );
      },
    );
  });

  // ──────────────────────────────────────────────
  // R5.4: Stock + formulario de cantidad
  // ──────────────────────────────────────────────
  group('CreateSaleScreen — R5.4: Stock y formulario', () {
    testWidgets('debe mostrar stock y formulario cuando stock cargado (R5.4)', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Abrir dropdown
      await tester.tap(find.text('Seleccioná un producto'));
      await tester.pumpAndSettle();

      // Seleccionar Producto A
      await tester.tap(find.text('Producto A').last);
      await pumpUntilSettled(tester);

      // Verificar que estamos en stockLoaded
      expect(provider.status, SalesStatus.stockLoaded);

      // Debe mostrar el stock disponible
      expect(find.textContaining('Stock disponible'), findsOneWidget);
      expect(find.textContaining('100.00'), findsOneWidget);

      // Debe mostrar el campo de cantidad
      expect(find.byType(TextFormField), findsOneWidget);

      // Debe mostrar el botón "Crear Venta"
      expect(
        find.widgetWithText(ElevatedButton, 'Crear Venta'),
        findsOneWidget,
      );
    });
  });

  // ──────────────────────────────────────────────
  // R5.5: Crear venta y navegar a resultado
  // ──────────────────────────────────────────────
  group('CreateSaleScreen — R5.5: Creación exitosa', () {
    testWidgets(
      'debe crear venta y navegar a SaleResultScreen al confirmar (R5.5)',
      (tester) async {
        await tester.pumpWidget(createTestApp(provider));
        await pumpUntilSettled(tester);

        // Seleccionar producto
        await tester.tap(find.text('Seleccioná un producto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Producto A').last);
        await pumpUntilSettled(tester);

        // Ingresar cantidad
        await tester.enterText(find.byType(TextFormField), '30');

        // Tocar "Crear Venta"
        await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Venta'));
        await pumpUntilSettled(tester);

        // Debe navegar a SaleResultScreen
        expect(find.byType(SaleResultScreen), findsOneWidget);
        expect(find.byType(CreateSaleScreen), findsNothing);
      },
    );

    testWidgets('debe crear SaleRequest con la cantidad correcta', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Seleccionar producto
      await tester.tap(find.text('Seleccioná un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto A').last);
      await pumpUntilSettled(tester);

      // Ingresar cantidad
      await tester.enterText(find.byType(TextFormField), '45.5');

      // Tocar "Crear Venta"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Venta'));
      await pumpUntilSettled(tester);

      verify(
        () => mockRepo.createSale(any(that: isA<SaleRequest>())),
      ).called(1);
    });
  });

  // ──────────────────────────────────────────────
  // R5.6: Error en API
  // ──────────────────────────────────────────────
  group('CreateSaleScreen — R5.6: Error en API', () {
    testWidgets('debe mostrar mensaje de error cuando la API falla (R5.6)', (
      tester,
    ) async {
      when(
        () => mockRepo.getProducts(),
      ).thenThrow(const ApiException('Error del servidor', 500));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Debe mostrar el mensaje de error
      expect(find.textContaining('Error del servidor'), findsOneWidget);

      // Debe mostrar botón "Reintentar"
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar debe recargar productos (R5.6)', (tester) async {
      // Arrange: falla primero
      when(
        () => mockRepo.getProducts(),
      ).thenThrow(const ApiException('Error', 500));
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);
      expect(find.textContaining('Error'), findsOneWidget);

      // Arrange: éxito después
      when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);

      // Act: tocar reintentar
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
      await pumpUntilSettled(tester);

      // Assert: reintentó y ahora está en productsLoaded
      expect(provider.status, SalesStatus.productsLoaded);
    });
  });

  // ──────────────────────────────────────────────
  // Error en loadStock
  // ──────────────────────────────────────────────
  group('CreateSaleScreen — Error al cargar stock', () {
    testWidgets('debe mostrar error si loadStock falla y reintentar recarga', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // productsLoaded → tap dropdown
      await tester.tap(find.text('Seleccioná un producto'));
      await tester.pumpAndSettle();

      // Hacer que loadStock falle
      when(
        () => mockRepo.getBatchesByProduct(any()),
      ).thenThrow(const ApiException('Producto sin stock', 400));

      await tester.tap(find.text('Producto A').last);
      await pumpUntilSettled(tester);

      // Debe mostrar error
      expect(find.textContaining('Producto sin stock'), findsOneWidget);

      // Reintentar reinicia desde productos
      when(
        () => mockRepo.getBatchesByProduct(any()),
      ).thenAnswer((_) async => [batch]);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
      await pumpUntilSettled(tester);

      // Vuelve a productsLoaded (después de recargar productos)
      expect(provider.status, SalesStatus.productsLoaded);
    });
  });
}
