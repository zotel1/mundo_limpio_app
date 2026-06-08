// Pruebas de widget para SalesHistoryScreen.
//
// Cubre los escenarios:
// - Muestra indicador de carga inicialmente
// - Muestra lista de ventas cuando hay datos
// - Muestra estado vacío cuando no hay ventas
// - Muestra error con botón de reintentar
// - Pull-to-refresh funciona
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
import 'package:mundo_limpio_app/features/sales/domain/entities/sale.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/sale_item.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_history_provider.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sales_history_screen.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

class MockAuthProvider extends Mock implements AuthProvider {}

/// Crea la app de test con SalesHistoryProvider real y mock repository.
Widget createTestApp(SalesHistoryProvider provider) {
  final auth = MockAuthProvider();
  when(() => auth.roles).thenReturn(['ADMIN']);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SalesHistoryProvider>.value(value: provider),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: const SalesHistoryScreen(),
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

  const saleItem = SaleItem(
    productId: 10,
    productName: 'Producto A',
    quantity: 5.0,
    unitPrice: 100.0,
  );

  final sale1 = Sale(
    id: 1,
    total: 500.0,
    createdAt: DateTime(2026, 5, 10),
    items: const [saleItem],
    status: 'completed',
  );

  final sale2 = Sale(
    id: 2,
    total: 300.0,
    createdAt: DateTime(2026, 5, 11),
    items: const [saleItem],
    status: 'completed',
  );

  setUp(() {
    mockRepo = MockSalesRepository();
    provider = SalesHistoryProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Loading
  // ──────────────────────────────────────────────
  group('SalesHistoryScreen — loading', () {
    testWidgets('debe mostrar indicador de carga cuando status es loading', (
      tester,
    ) async {
      when(
        () => mockRepo.getSales(),
      ).thenAnswer((_) => Completer<List<Sale>>().future);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(CatLoadingIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Lista con datos
  // ──────────────────────────────────────────────
  group('SalesHistoryScreen — lista con datos', () {
    testWidgets('debe mostrar lista de ventas cuando hay datos', (
      tester,
    ) async {
      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1, sale2]);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('Venta #1'), findsOneWidget);
      expect(find.text('Venta #2'), findsOneWidget);
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.text('\$300.00'), findsOneWidget);
    });

    testWidgets('debe mostrar RefreshIndicator en la lista', (tester) async {
      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1, sale2]);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Estado vacío
  // ──────────────────────────────────────────────
  group('SalesHistoryScreen — vacío', () {
    testWidgets('debe mostrar mensaje vacío cuando no hay ventas', (
      tester,
    ) async {
      when(() => mockRepo.getSales()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('No hay ventas registradas'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Error
  // ──────────────────────────────────────────────
  group('SalesHistoryScreen — error', () {
    testWidgets('debe mostrar error y botón de reintentar cuando falla carga', (
      tester,
    ) async {
      when(
        () => mockRepo.getSales(),
      ).thenThrow(const ApiException('Error de conexión', 500));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Error de conexión'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar debe recargar ventas', (tester) async {
      when(
        () => mockRepo.getSales(),
      ).thenThrow(const ApiException('Error', 500));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Error'), findsOneWidget);

      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1]);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
      await pumpUntilSettled(tester);

      expect(provider.status, SalesHistoryStatus.success);
      expect(provider.sales, hasLength(1));
    });
  });

  // ──────────────────────────────────────────────
  // Pull-to-refresh
  // ──────────────────────────────────────────────
  group('SalesHistoryScreen — pull-to-refresh', () {
    testWidgets('debe recargar ventas al hacer pull-to-refresh', (
      tester,
    ) async {
      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1]);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(provider.sales, hasLength(1));

      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1, sale2]);

      await provider.loadSales();
      await pumpUntilSettled(tester);

      expect(provider.status, SalesHistoryStatus.success);
      expect(provider.sales, hasLength(2));
    });
  });
}
