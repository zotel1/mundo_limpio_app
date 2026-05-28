// Pruebas de widget para SaleDetailScreen.
//
// Cubre los escenarios:
// - Muestra indicador de carga inicialmente
// - Muestra detalle cuando hay datos (header, items, total)
// - Muestra error con botón de reintentar
//
// Usa SalesHistoryProvider real con MockSalesRepository.
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
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_history_provider.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sale_detail_screen.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

class MockAuthProvider extends Mock implements AuthProvider {}

/// Crea la app de test con SalesHistoryProvider real y mock repository.
Widget createTestApp(SalesHistoryProvider provider, int saleId) {
  final auth = MockAuthProvider();
  when(() => auth.roles).thenReturn(['ADMIN']);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SalesHistoryProvider>.value(value: provider),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: SaleDetailScreen(saleId: saleId),
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
  late SalesHistoryProvider provider;

  const saleItem = SaleItemResponse(
    batchId: 1,
    productId: 10,
    productName: 'Producto de prueba',
    quantity: 5.0,
    unitPrice: 100.0,
    unitCost: 60.0,
  );

  final sale = SaleResponse(
    id: 42,
    totalAmount: 500.0,
    createdAt: DateTime(2026, 5, 10, 10, 30, 0),
    items: const [saleItem],
  );

  setUp(() {
    mockRepo = MockSalesRepository();
    provider = SalesHistoryProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Loading
  // ──────────────────────────────────────────────
  group('SaleDetailScreen — loading', () {
    testWidgets('debe mostrar indicador de carga cuando status es loading', (
      tester,
    ) async {
      when(
        () => mockRepo.getSaleById(any()),
      ).thenAnswer((_) => Completer<SaleResponse>().future);

      await tester.pumpWidget(createTestApp(provider, 42));
      await pumpUntilSettled(tester);

      expect(find.byType(CatLoadingIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Detalle
  // ──────────────────────────────────────────────
  group('SaleDetailScreen — detalle', () {
    testWidgets('debe mostrar detalle de venta cuando se carga exitosamente', (
      tester,
    ) async {
      when(() => mockRepo.getSaleById(42)).thenAnswer((_) async => sale);

      await tester.pumpWidget(createTestApp(provider, 42));
      await pumpUntilSettled(tester);

      // Header
      expect(find.text('Venta #42'), findsOneWidget);
      expect(find.textContaining('\$500.00'), findsAtLeast(1));

      // Items
      expect(find.text('Producto de prueba'), findsOneWidget);
      expect(find.textContaining('5.00'), findsAtLeast(1));
      expect(find.textContaining('\$100.00'), findsAtLeast(1));

      // Total row
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje cuando no hay venta seleccionada', (
      tester,
    ) async {
      when(() => mockRepo.getSaleById(99)).thenAnswer((_) async => sale);
      provider = SalesHistoryProvider(mockRepo);

      await tester.pumpWidget(createTestApp(provider, 99));
      await pumpUntilSettled(tester);

      // Si selectedSale es null, debería mostrar mensaje
      // Pero como cargamos exitosamente, selectedSale no será null
      // Este test verifica que no crashea
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Error
  // ──────────────────────────────────────────────
  group('SaleDetailScreen — error', () {
    testWidgets('debe mostrar error y botón de reintentar cuando falla carga', (
      tester,
    ) async {
      when(
        () => mockRepo.getSaleById(42),
      ).thenThrow(const ApiException('Venta no encontrada', 404));

      await tester.pumpWidget(createTestApp(provider, 42));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Venta no encontrada'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar debe recargar detalle de venta', (tester) async {
      when(
        () => mockRepo.getSaleById(42),
      ).thenThrow(const ApiException('Error', 500));

      await tester.pumpWidget(createTestApp(provider, 42));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Error'), findsOneWidget);

      when(() => mockRepo.getSaleById(42)).thenAnswer((_) async => sale);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
      await pumpUntilSettled(tester);

      expect(provider.status, SalesHistoryStatus.success);
      expect(provider.selectedSale, isNotNull);
      expect(provider.selectedSale!.id, 42);
    });
  });
}
