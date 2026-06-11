// Tests unitarios para InventoryProvider.
// Verifica el ciclo completo de estados del provider:
// - Estado inicial idle con datos nulos/vacíos
// - loadInventory: idle → loading → inventoryLoaded | error
// - loadLowStock: idle → loading → lowStockLoaded | error
// - adjustStock: → loading → success | error
// - reset: cualquier estado → idle con datos limpiados
//
// TDD: RED — test escrito antes que la implementación

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/adjustment.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/stock_item.dart';
import 'package:mundo_limpio_app/features/inventory/domain/repository/inventory_repository.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/provider/inventory_provider.dart';

// Mock de InventoryRepository para aislar el provider de la capa de datos
class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late InventoryProvider provider;

  const testProductId = 1;
  const testInventory = StockItem(
    productId: testProductId,
    productName: 'Jabón Líquido',
    currentStock: 50.0,
    minStockThreshold: 10.0,
  );
  final testLowStockItems = [
    const StockItem(
      productId: 2,
      productName: 'Detergente',
      currentStock: 3.0,
      minStockThreshold: 20.0,
    ),
    const StockItem(
      productId: 3,
      productName: 'Lavandina',
      currentStock: 5.0,
      minStockThreshold: 15.0,
    ),
  ];
  const testAdjustmentRequest = Adjustment(
    type: AdjustmentType.adjustment,
    quantity: 10.0,
    reason: 'ajuste manual',
  );
  const testAdjustmentResponse = StockItem(
    productId: testProductId,
    productName: 'Jabón Líquido',
    currentStock: 60.0,
    minStockThreshold: 10.0,
  );

  setUp(() {
    mockRepository = MockInventoryRepository();
    provider = InventoryProvider(repository: mockRepository);
  });

  // ──────────────────────────────────────────────
  // Test 1: Estado inicial
  // ──────────────────────────────────────────────
  group('1. estado inicial', () {
    test('debe tener status idle y datos nulos/vacíos por defecto', () {
      expect(provider.status, InventoryStatus.idle);
      expect(provider.currentInventory, isNull);
      expect(provider.lowStockItems, isEmpty);
      expect(provider.lastAdjustment, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // Tests 2-3: loadInventory
  // ──────────────────────────────────────────────
  group('2. loadInventory', () {
    test('success: idle → loading → inventoryLoaded con data', () async {
      final completer = Completer<StockItem>();
      when(
        () => mockRepository.getInventory(testProductId),
      ).thenAnswer((_) => completer.future);

      // Llamar sin await para verificar estado loading intermedio
      final future = provider.loadInventory(testProductId);

      expect(
        provider.status,
        InventoryStatus.loading,
        reason: 'debe transicionar a loading inmediatamente',
      );

      completer.complete(testInventory);
      await future;

      expect(provider.status, InventoryStatus.inventoryLoaded);
      expect(provider.currentInventory?.productId, testProductId);
      expect(provider.currentInventory?.productName, 'Jabón Líquido');
      expect(provider.currentInventory?.currentStock, 50.0);
      expect(provider.currentInventory?.minStockThreshold, 10.0);
      expect(provider.errorMessage, isNull);
    });

    test('error: idle → loading → error con ApiException', () async {
      final completer = Completer<StockItem>();
      when(
        () => mockRepository.getInventory(testProductId),
      ).thenAnswer((_) => completer.future);

      final future = provider.loadInventory(testProductId);

      expect(provider.status, InventoryStatus.loading);

      completer.completeError(
        const UnknownApiException('Producto no encontrado', 404),
      );
      await future;

      expect(provider.status, InventoryStatus.error);
      expect(provider.errorMessage, 'Producto no encontrado');
      expect(provider.currentInventory, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // Tests 4-5: loadLowStock
  // ──────────────────────────────────────────────
  group('3. loadLowStock', () {
    test('success: idle → loading → lowStockLoaded con lista', () async {
      final completer = Completer<List<StockItem>>();
      when(
        () => mockRepository.getLowStock(),
      ).thenAnswer((_) => completer.future);

      final future = provider.loadLowStock();

      expect(provider.status, InventoryStatus.loading);

      completer.complete(testLowStockItems);
      await future;

      expect(provider.status, InventoryStatus.lowStockLoaded);
      expect(provider.lowStockItems, hasLength(2));
      expect(provider.lowStockItems[0].productName, 'Detergente');
      expect(provider.lowStockItems[1].productName, 'Lavandina');
      expect(provider.lowStockItems[0].currentStock, 3.0);
      expect(provider.lowStockItems[1].currentStock, 5.0);
      expect(provider.errorMessage, isNull);
    });

    test('error: idle → loading → error con ApiException', () async {
      final completer = Completer<List<StockItem>>();
      when(
        () => mockRepository.getLowStock(),
      ).thenAnswer((_) => completer.future);

      final future = provider.loadLowStock();

      expect(provider.status, InventoryStatus.loading);

      completer.completeError(
        const UnknownApiException('Error del servidor', 500),
      );
      await future;

      expect(provider.status, InventoryStatus.error);
      expect(provider.errorMessage, 'Error del servidor');
      expect(provider.lowStockItems, isEmpty);
    });
  });

  // ──────────────────────────────────────────────
  // Tests 6-8: adjustStock
  // ──────────────────────────────────────────────
  group('4. adjustStock', () {
    test('success: → loading → success con response', () async {
      final completer = Completer<StockItem>();
      when(
        () => mockRepository.adjustStock(testProductId, testAdjustmentRequest),
      ).thenAnswer((_) => completer.future);

      final future = provider.adjustStock(testProductId, testAdjustmentRequest);

      expect(provider.status, InventoryStatus.loading);

      completer.complete(testAdjustmentResponse);
      await future;

      expect(provider.status, InventoryStatus.success);
      expect(provider.lastAdjustment?.currentStock, 60.0);
      expect(provider.errorMessage, isNull);
    });

    test(
      'error 400: → loading → error con mensaje (stock insuficiente)',
      () async {
        final completer = Completer<StockItem>();
        when(
          () =>
              mockRepository.adjustStock(testProductId, testAdjustmentRequest),
        ).thenAnswer((_) => completer.future);

        final future = provider.adjustStock(
          testProductId,
          testAdjustmentRequest,
        );

        expect(provider.status, InventoryStatus.loading);

        completer.completeError(
          const UnknownApiException('Stock insuficiente', 400),
        );
        await future;

        expect(provider.status, InventoryStatus.error);
        expect(provider.errorMessage, 'Stock insuficiente');
        expect(provider.lastAdjustment, isNull);
      },
    );

    test(
      'error 409: → loading → error con mensaje (conflicto de versión)',
      () async {
        final completer = Completer<StockItem>();
        when(
          () =>
              mockRepository.adjustStock(testProductId, testAdjustmentRequest),
        ).thenAnswer((_) => completer.future);

        final future = provider.adjustStock(
          testProductId,
          testAdjustmentRequest,
        );

        expect(provider.status, InventoryStatus.loading);

        completer.completeError(
          const UnknownApiException('Conflicto de versión', 409),
        );
        await future;

        expect(provider.status, InventoryStatus.error);
        expect(provider.errorMessage, 'Conflicto de versión');
        expect(provider.lastAdjustment, isNull);
      },
    );
  });

  // ──────────────────────────────────────────────
  // Test 9-10: reset
  // ──────────────────────────────────────────────
  group('5. reset', () {
    test('tras inventoryLoaded vuelve a idle limpiando datos', () async {
      when(
        () => mockRepository.getInventory(testProductId),
      ).thenAnswer((_) async => testInventory);
      await provider.loadInventory(testProductId);

      expect(provider.status, InventoryStatus.inventoryLoaded);
      expect(provider.currentInventory, isNotNull);

      provider.reset();

      expect(provider.status, InventoryStatus.idle);
      expect(provider.currentInventory, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.lastAdjustment, isNull);
      expect(provider.lowStockItems, isEmpty);
    });

    test('tras error vuelve a idle limpiando errorMessage', () async {
      when(
        () => mockRepository.getInventory(testProductId),
      ).thenThrow(const UnknownApiException('Error', 500));
      await provider.loadInventory(testProductId);

      expect(provider.status, InventoryStatus.error);
      expect(provider.errorMessage, isNotNull);

      provider.reset();

      expect(provider.status, InventoryStatus.idle);
      expect(provider.errorMessage, isNull);
      expect(provider.currentInventory, isNull);
    });
  });
}
