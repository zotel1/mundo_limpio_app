// Pruebas unitarias para InventoryRepositoryImpl — offline-aware.
//
// Verifica el comportamiento online/offline del repositorio:
// - getInventory online: llama Api + cachea en InventoryCacheDao
// - getInventory offline: lee desde InventoryCacheDao (cache hit/miss)
// - getLowStock online: llama Api + cachea todos los items
// - getLowStock offline: lee desde InventoryCacheDao
// - adjustStock online: llama Api directamente
// - adjustStock offline: encola en InventoryPendingDao + retorna indica pending
// - Errores online: propaga ApiException desde InventoryApi
//
// TDD: RED → GREEN → TRIANGULATE

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';
import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_cache_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_pending_dao.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart'
    as dto;
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/data/repository/inventory_repository_impl.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/adjustment.dart';

// ─── Mocks ──────────────────────────────────────────────────────

class MockInventoryApi extends Mock implements InventoryApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockInventoryCacheDao extends Mock implements InventoryCacheDao {}

class MockInventoryPendingDao extends Mock implements InventoryPendingDao {}

void main() {
  late MockInventoryApi mockInventoryApi;
  late MockConnectivityService mockConnectivity;
  late MockInventoryCacheDao mockCacheDao;
  late MockInventoryPendingDao mockPendingDao;
  late InventoryRepositoryImpl repository;

  const testProductId = 1;

  setUpAll(() {
    registerFallbackValue(
      InventoryPendingQueueCompanion.insert(productId: 0, payload: ''),
    );
    registerFallbackValue(
      InventoryCacheData(
        productId: 0,
        productName: '',
        currentStock: 0,
        minStockThreshold: 0,
        updatedAt: DateTime(2025),
      ),
    );
    registerFallbackValue(
      const dto.AdjustmentRequest(
        type: dto.AdjustmentType.ADJUSTMENT,
        quantity: 0,
        reason: '',
      ),
    );
    registerFallbackValue(
      const Adjustment(
        type: AdjustmentType.adjustment,
        quantity: 0,
        reason: '',
      ),
    );
  });

  setUp(() {
    mockInventoryApi = MockInventoryApi();
    mockConnectivity = MockConnectivityService();
    mockCacheDao = MockInventoryCacheDao();
    mockPendingDao = MockInventoryPendingDao();

    repository = InventoryRepositoryImpl(
      inventoryApi: mockInventoryApi,
      connectivity: mockConnectivity,
      inventoryCacheDao: mockCacheDao,
      inventoryPendingDao: mockPendingDao,
    );
  });

  // ================================================================
  // getInventory — online
  // ================================================================

  group('getInventory online', () {
    setUp(() {
      when(() => mockConnectivity.isOnline).thenReturn(true);
    });

    test(
      'llama InventoryApi.getInventory y retorna InventoryResponse',
      () async {
        final expectedResponse = const InventoryResponse(
          productId: testProductId,
          productName: 'Jabón Líquido',
          currentStock: 50.0,
          minStockThreshold: 10.0,
        );
        when(
          () => mockInventoryApi.getInventory(testProductId),
        ).thenAnswer((_) async => expectedResponse);
        when(() => mockCacheDao.upsertAll(any())).thenAnswer((_) async {});

        final result = await repository.getInventory(testProductId);

        expect(result.productId, testProductId);
        expect(result.productName, 'Jabón Líquido');
        expect(result.currentStock, 50.0);
        verify(() => mockInventoryApi.getInventory(testProductId)).called(1);
      },
    );

    test('cachea la respuesta en InventoryCacheDao', () async {
      final expectedResponse = const InventoryResponse(
        productId: testProductId,
        productName: 'Jabón Líquido',
        currentStock: 50.0,
        minStockThreshold: 10.0,
      );
      when(
        () => mockInventoryApi.getInventory(testProductId),
      ).thenAnswer((_) async => expectedResponse);
      when(() => mockCacheDao.upsertAll(any())).thenAnswer((_) async {});

      await repository.getInventory(testProductId);

      final captured =
          verify(() => mockCacheDao.upsertAll(captureAny())).captured.single
              as List<InventoryCacheData>;
      expect(captured, hasLength(1));
      expect(captured[0].productId, testProductId);
      expect(captured[0].productName, 'Jabón Líquido');
      expect(captured[0].currentStock, 50.0);
      expect(captured[0].minStockThreshold, 10.0);
    });

    test('propaga ApiException cuando la API falla', () async {
      when(
        () => mockInventoryApi.getInventory(testProductId),
      ).thenThrow(const ApiException('Producto no encontrado', 404));

      expect(
        () => repository.getInventory(testProductId),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ================================================================
  // getInventory — offline
  // ================================================================

  group('getInventory offline', () {
    setUp(() {
      when(() => mockConnectivity.isOnline).thenReturn(false);
    });

    test('lee desde InventoryCacheDao cuando hay cache', () async {
      final cachedData = InventoryCacheData(
        productId: testProductId,
        productName: 'Jabón Líquido',
        currentStock: 50.0,
        minStockThreshold: 10.0,
        updatedAt: DateTime(2025, 1, 1),
      );
      when(
        () => mockCacheDao.getByProductId(testProductId),
      ).thenAnswer((_) async => cachedData);

      final result = await repository.getInventory(testProductId);

      expect(result.productId, testProductId);
      expect(result.productName, 'Jabón Líquido');
      expect(result.currentStock, 50.0);
      expect(result.minStockThreshold, 10.0);

      // NO llamó a la API
      verifyNever(() => mockInventoryApi.getInventory(testProductId));
      verify(() => mockCacheDao.getByProductId(testProductId)).called(1);
    });

    test('retorna producto con productId=-1 cuando no hay cache', () async {
      when(
        () => mockCacheDao.getByProductId(testProductId),
      ).thenAnswer((_) async => null);

      final result = await repository.getInventory(testProductId);

      expect(result.productId, -1);
      verifyNever(() => mockInventoryApi.getInventory(testProductId));
    });
  });

  // ================================================================
  // getLowStock — online
  // ================================================================

  group('getLowStock online', () {
    setUp(() {
      when(() => mockConnectivity.isOnline).thenReturn(true);
    });

    test('llama InventoryApi.getLowStock y retorna lista', () async {
      final expectedItems = [
        const InventoryResponse(
          productId: 1,
          productName: 'Jabón Líquido',
          currentStock: 5.0,
          minStockThreshold: 10.0,
        ),
        const InventoryResponse(
          productId: 2,
          productName: 'Detergente',
          currentStock: 3.0,
          minStockThreshold: 20.0,
        ),
      ];
      when(
        () => mockInventoryApi.getLowStock(),
      ).thenAnswer((_) async => expectedItems);
      when(() => mockCacheDao.upsertAll(any())).thenAnswer((_) async {});

      final result = await repository.getLowStock();

      expect(result, hasLength(2));
      expect(result[0].productId, 1);
      expect(result[0].productName, 'Jabón Líquido');
      expect(result[0].currentStock, 5.0);
      expect(result[1].productId, 2);
      verify(() => mockInventoryApi.getLowStock()).called(1);
    });

    test('cachea todos los items devueltos', () async {
      final expectedItems = [
        const InventoryResponse(
          productId: 1,
          productName: 'Jabón Líquido',
          currentStock: 5.0,
          minStockThreshold: 10.0,
        ),
        const InventoryResponse(
          productId: 2,
          productName: 'Detergente',
          currentStock: 3.0,
          minStockThreshold: 20.0,
        ),
      ];
      when(
        () => mockInventoryApi.getLowStock(),
      ).thenAnswer((_) async => expectedItems);
      when(() => mockCacheDao.upsertAll(any())).thenAnswer((_) async {});

      await repository.getLowStock();

      final captured =
          verify(() => mockCacheDao.upsertAll(captureAny())).captured.single
              as List<InventoryCacheData>;
      expect(captured, hasLength(2));
      expect(captured[0].productId, 1);
      expect(captured[0].currentStock, 5.0);
      expect(captured[1].productId, 2);
      expect(captured[1].currentStock, 3.0);
    });

    test('propaga ApiException cuando la API falla', () async {
      when(
        () => mockInventoryApi.getLowStock(),
      ).thenThrow(const ApiException('Error interno', 500));

      expect(() => repository.getLowStock(), throwsA(isA<ApiException>()));
    });
  });

  // ================================================================
  // getLowStock — offline
  // ================================================================

  group('getLowStock offline', () {
    setUp(() {
      when(() => mockConnectivity.isOnline).thenReturn(false);
    });

    test('lee desde InventoryCacheDao cuando hay cache', () async {
      final cachedItems = [
        InventoryCacheData(
          productId: 1,
          productName: 'Jabón Líquido',
          currentStock: 5.0,
          minStockThreshold: 10.0,
          updatedAt: DateTime(2025, 1, 1),
        ),
        InventoryCacheData(
          productId: 2,
          productName: 'Detergente',
          currentStock: 3.0,
          minStockThreshold: 20.0,
          updatedAt: DateTime(2025, 1, 2),
        ),
      ];
      when(() => mockCacheDao.getAll()).thenAnswer((_) async => cachedItems);

      final result = await repository.getLowStock();

      expect(result, hasLength(2));
      expect(result[0].productId, 1);
      expect(result[0].productName, 'Jabón Líquido');
      expect(result[0].currentStock, 5.0);
      expect(result[0].minStockThreshold, 10.0);
      expect(result[1].productId, 2);
      expect(result[1].currentStock, 3.0);

      verifyNever(() => mockInventoryApi.getLowStock());
      verify(() => mockCacheDao.getAll()).called(1);
    });

    test('retorna lista vacía cuando el cache está vacío', () async {
      when(() => mockCacheDao.getAll()).thenAnswer((_) async => []);

      final result = await repository.getLowStock();

      expect(result, isEmpty);
      verifyNever(() => mockInventoryApi.getLowStock());
    });
  });

  // ================================================================
  // adjustStock — online
  // ================================================================

  group('adjustStock online', () {
    const testRequest = Adjustment(
      type: AdjustmentType.adjustment,
      quantity: 10.0,
      reason: 'ajuste manual',
    );

    setUp(() {
      when(() => mockConnectivity.isOnline).thenReturn(true);
    });

    test('llama InventoryApi.adjustStock y retorna StockItem', () async {
      final expectedResponse = InventoryResponse(
        productId: testProductId,
        productName: 'Jabón Líquido',
        currentStock: 60.0,
        minStockThreshold: 10.0,
      );
      when(
        () => mockInventoryApi.adjustStock(testProductId, any()),
      ).thenAnswer((_) async => expectedResponse);

      final result = await repository.adjustStock(testProductId, testRequest);

      expect(result.currentStock, 60.0);
      expect(result.productId, testProductId);
      verify(
        () => mockInventoryApi.adjustStock(testProductId, any()),
      ).called(1);
    });

    test('propaga ApiException cuando la API falla', () async {
      when(
        () => mockInventoryApi.adjustStock(testProductId, any()),
      ).thenThrow(const ApiException('Conflicto de versión', 409));

      expect(
        () => repository.adjustStock(testProductId, testRequest),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ================================================================
  // adjustStock — offline
  // ================================================================

  group('adjustStock offline', () {
    const testRequest = Adjustment(
      type: AdjustmentType.adjustment,
      quantity: 10.0,
      reason: 'ajuste manual',
    );

    setUp(() {
      when(() => mockConnectivity.isOnline).thenReturn(false);
    });

    test('encola el ajuste en InventoryPendingDao', () async {
      when(() => mockPendingDao.insert(any())).thenAnswer((_) async => 42);

      await repository.adjustStock(testProductId, testRequest);

      final captured =
          verify(() => mockPendingDao.insert(captureAny())).captured.single
              as InventoryPendingQueueCompanion;
      expect(captured.productId.present, isTrue);
      expect(captured.productId.value, testProductId);
      // status usa el default de la DB ('pending') → absent
      expect(captured.status.present, isFalse);
      expect(captured.payload.present, isTrue);
    });

    test('el payload contiene el Adjustment serializado', () async {
      when(() => mockPendingDao.insert(any())).thenAnswer((_) async => 42);

      await repository.adjustStock(testProductId, testRequest);

      final captured =
          verify(() => mockPendingDao.insert(captureAny())).captured.single
              as InventoryPendingQueueCompanion;
      final payload = captured.payload.value;
      expect(payload, contains('ADJUSTMENT'));
      expect(payload, contains('10.0'));
      expect(payload, contains('ajuste manual'));
    });

    test('retorna StockItem con productId=-1 (pendiente)', () async {
      when(() => mockPendingDao.insert(any())).thenAnswer((_) async => 42);

      final result = await repository.adjustStock(testProductId, testRequest);

      expect(result.productId, -1);
    });

    test('con BREAKAGE: payload correcto y marcador pendiente', () async {
      const breakageRequest = Adjustment(
        type: AdjustmentType.breakage,
        quantity: -5.0,
        reason: 'quebrado',
      );
      when(() => mockPendingDao.insert(any())).thenAnswer((_) async => 42);

      final result = await repository.adjustStock(
        testProductId,
        breakageRequest,
      );

      expect(result.productId, -1);

      final captured =
          verify(() => mockPendingDao.insert(captureAny())).captured.single
              as InventoryPendingQueueCompanion;
      expect(captured.payload.value, contains('BREAKAGE'));
      expect(captured.payload.value, contains('-5.0'));
    });
  });
}
