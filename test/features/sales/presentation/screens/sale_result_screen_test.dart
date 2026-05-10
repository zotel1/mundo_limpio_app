// Pruebas de widget para SaleResultScreen.
//
// Cubre los 3 escenarios de R6:
// - R6.1: Muestra todos los detalles de la venta (id, total, items)
// - R6.2: "Nueva Venta" resetea provider y navega hacia atrás
// - R6.3: "Volver al Inicio" navega hacia atrás
//
// TDD: RED — test escrito antes que la implementación de la pantalla

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_provider.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sale_result_screen.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

/// Crea la app de test con NavigationStack para verificar pop.
///
/// La pantalla inicial tiene un botón "IR" que navega a SaleResultScreen.
/// Esto permite testear que pop regresa a la pantalla anterior.
Widget createTestApp(SalesProvider provider, SaleResponse sale) {
  return ChangeNotifierProvider<SalesProvider>.value(
    value: provider,
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleResultScreen(sale: sale),
              ),
            ),
            child: const Text('IR'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockSalesRepository mockRepo;
  late SalesProvider provider;

  final testDate = DateTime(2026, 5, 10, 10, 30, 0);
  const saleItem = SaleItemResponse(
    batchId: 42,
    quantity: 30.0,
    unitPrice: 150.00,
    unitCost: 100.00,
  );
  final sale = SaleResponse(
    id: 1,
    totalAmount: 375.00,
    createdAt: testDate,
    items: const [saleItem],
  );

  setUpAll(() {
    registerFallbackValue(const SaleRequest(productId: 0, quantity: 0));
  });

  setUp(() {
    mockRepo = MockSalesRepository();
    provider = SalesProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // R6.1: Detalles de la venta
  // ──────────────────────────────────────────────
  group('SaleResultScreen — R6.1: Detalles de venta', () {
    testWidgets('debe mostrar todos los detalles de la venta (R6.1)',
        (tester) async {
      await tester.pumpWidget(createTestApp(provider, sale));
      await tester.pumpAndSettle();

      // Navegar a SaleResultScreen
      await tester.tap(find.widgetWithText(ElevatedButton, 'IR'));
      await tester.pumpAndSettle();

      // Título del AppBar
      expect(find.text('Venta Creada'), findsOneWidget);

      // Icono de éxito
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Mensaje de éxito
      expect(find.text('¡Venta creada exitosamente!'), findsOneWidget);

      // ID de la venta
      expect(find.textContaining('#1'), findsOneWidget);

      // Total
      expect(find.textContaining('\$375.00'), findsOneWidget);

      // Detalle del item
      expect(find.textContaining('42'), findsOneWidget);
      expect(find.textContaining('30.0'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // R6.2: "Nueva Venta"
  // ──────────────────────────────────────────────
  group('SaleResultScreen — R6.2: Nueva Venta', () {
    testWidgets('"Nueva Venta" debe resetear provider y navegar atrás (R6.2)',
        (tester) async {
      // Arrange: poner el provider en estado success
      when(() => mockRepo.getProducts())
          .thenAnswer((_) async => []);
      when(() => mockRepo.getBatchesByProduct(any()))
          .thenAnswer((_) async => []);
      when(() => mockRepo.createSale(any()))
          .thenAnswer((_) async => sale);

      await tester.pumpWidget(createTestApp(provider, sale));
      await tester.pumpAndSettle();

      // Navegar a SaleResultScreen
      await tester.tap(find.widgetWithText(ElevatedButton, 'IR'));
      await tester.pumpAndSettle();

      // Verificar que SaleResultScreen se muestra
      expect(find.byType(SaleResultScreen), findsOneWidget);

      // Tap "Nueva Venta"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Nueva Venta'));
      await tester.pumpAndSettle();

      // Provider debe estar reseteado
      expect(provider.status, SalesStatus.idle);
      expect(provider.lastSale, isNull);

      // Debe navegar atrás (pop)
      expect(find.byType(SaleResultScreen), findsNothing);
      expect(find.text('IR'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // R6.3: "Volver al Inicio"
  // ──────────────────────────────────────────────
  group('SaleResultScreen — R6.3: Volver al Inicio', () {
    testWidgets(
        '"Volver al Inicio" debe resetear provider y navegar atrás (R6.3)',
        (tester) async {
      await tester.pumpWidget(createTestApp(provider, sale));
      await tester.pumpAndSettle();

      // Navegar a SaleResultScreen
      await tester.tap(find.widgetWithText(ElevatedButton, 'IR'));
      await tester.pumpAndSettle();

      expect(find.byType(SaleResultScreen), findsOneWidget);

      // Tap "Volver al Inicio"
      await tester.tap(find.widgetWithText(TextButton, 'Volver al Inicio'));
      await tester.pumpAndSettle();

      // Provider debe estar reseteado
      expect(provider.status, SalesStatus.idle);
      expect(provider.lastSale, isNull);

      // Debe navegar atrás (pop)
      expect(find.byType(SaleResultScreen), findsNothing);
      expect(find.text('IR'), findsOneWidget);
    });
  });
}
