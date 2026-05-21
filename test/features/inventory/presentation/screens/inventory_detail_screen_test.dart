// Pruebas de widget para InventoryDetailScreen.
//
// Cubre 4 escenarios:
// - R7.1: Muestra loading spinner
// - R7.2: Muestra detalle de stock con info del producto
// - R7.3: Muestra error con botón reintentar
// - R7.4: Botón "Ajustar Stock" abre el diálogo
//
// Usa InventoryProvider real con MockInventoryRepository.
//
// TDD: RED — test escrito antes que la implementación de la pantalla

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/domain/repository/inventory_repository.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/provider/inventory_provider.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_detail_screen.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

/// Crea la app de test con Provider para probar el detail screen.
Widget createTestApp(InventoryProvider provider, {required int productId}) {
  return ChangeNotifierProvider<InventoryProvider>.value(
    value: provider,
    child: MaterialApp(home: InventoryDetailScreen(productId: productId)),
  );
}

/// Helper para pump repetido hasta que los async tasks resuelven.
Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockInventoryRepository mockRepo;
  late InventoryProvider provider;

  const testProductId = 1;
  const testInventory = InventoryResponse(
    productId: testProductId,
    productName: 'Jabón Líquido',
    currentStock: 50.0,
    minStockThreshold: 10.0,
  );

  setUp(() {
    mockRepo = MockInventoryRepository();
    provider = InventoryProvider(repository: mockRepo);
  });

  // ──────────────────────────────────────────────
  // R7.1: Loading spinner
  // ──────────────────────────────────────────────
  group('InventoryDetailScreen — R7.1: Loading', () {
    testWidgets('debe mostrar spinner mientras carga el detalle', (
      tester,
    ) async {
      final completer = Completer<InventoryResponse>();
      when(
        () => mockRepo.getInventory(testProductId),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        createTestApp(provider, productId: testProductId),
      );
      // Un frame para que initState → loadInventory → loading
      await tester.pump();

      expect(find.byType(CatLoadingIndicator), findsOneWidget);

      completer.complete(testInventory);
    });
  });

  // ──────────────────────────────────────────────
  // R7.2: Stock detail
  // ──────────────────────────────────────────────
  group('InventoryDetailScreen — R7.2: Stock detail', () {
    testWidgets('debe mostrar info de stock del producto', (tester) async {
      when(
        () => mockRepo.getInventory(testProductId),
      ).thenAnswer((_) async => testInventory);

      await tester.pumpWidget(
        createTestApp(provider, productId: testProductId),
      );
      await pumpUntilSettled(tester);

      // Debe mostrar el nombre del producto (en AppBar y cuerpo)
      expect(find.text('Jabón Líquido'), findsAtLeast(1));

      // Debe mostrar stock actual y umbral
      expect(find.textContaining('50.00'), findsAtLeast(1));
      expect(find.textContaining('10.00'), findsAtLeast(1));

      // Debe mostrar el botón "Ajustar Stock"
      expect(
        find.widgetWithText(ElevatedButton, 'Ajustar Stock'),
        findsOneWidget,
      );
    });
  });

  // ──────────────────────────────────────────────
  // R7.3: Error con reintentar
  // ──────────────────────────────────────────────
  group('InventoryDetailScreen — R7.3: Error state', () {
    testWidgets('debe mostrar error con botón reintentar', (tester) async {
      when(
        () => mockRepo.getInventory(testProductId),
      ).thenThrow(const ApiException('Error de conexión', 500));

      await tester.pumpWidget(
        createTestApp(provider, productId: testProductId),
      );
      await pumpUntilSettled(tester);

      // Debe mostrar mensaje de error
      expect(find.textContaining('Error de conexión'), findsOneWidget);

      // Debe mostrar botón reintentar
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // R7.4: Botón ajustar abre dialog
  // ──────────────────────────────────────────────
  group('InventoryDetailScreen — R7.4: Adjust button', () {
    testWidgets('botón Ajustar Stock abre el diálogo de ajuste', (
      tester,
    ) async {
      when(
        () => mockRepo.getInventory(testProductId),
      ).thenAnswer((_) async => testInventory);

      await tester.pumpWidget(
        createTestApp(provider, productId: testProductId),
      );
      await pumpUntilSettled(tester);

      // Tocar "Ajustar Stock"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ajustar Stock'));
      await tester.pumpAndSettle();

      // Debe mostrar el diálogo con título "Ajustar Stock"
      expect(
        find.text('Ajustar Stock'),
        findsNWidgets(2),
      ); // botón y título dialog
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });
  });
}
