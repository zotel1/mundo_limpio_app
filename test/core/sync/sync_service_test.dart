// Pruebas unitarias para SyncService.
// Verifica el comportamiento de sincronización al reconectar:
// - FIFO processing de inventory_pending_queue
// - Failed operations no bloquean la cola
// - Actualización de draftCount
// - lastSync se actualiza después del sync
//
// TDD: RED → GREEN — implementación final

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';
import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/draft_sale_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_cache_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_pending_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/product_cache_dao.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/sync/sync_service.dart';
import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/sales/data/api/sales_api.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';

// ─── Mocks ────────────────────────────────────────────────────

class MockConnectivity extends Mock implements Connectivity {}

class MockInventoryPendingDao extends Mock implements InventoryPendingDao {}

class MockInventoryApi extends Mock implements InventoryApi {}

class MockProductCacheDao extends Mock implements ProductCacheDao {}

class MockInventoryCacheDao extends Mock implements InventoryCacheDao {}

class MockDraftSaleDao extends Mock implements DraftSaleDao {}

class MockSalesApi extends Mock implements SalesApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      AdjustmentRequest(
        type: AdjustmentType.ADJUSTMENT,
        quantity: 1.0,
        reason: 'test',
      ),
    );
  });

  late ConnectivityService connectivityService;
  late StreamController<List<ConnectivityResult>> connectivityController;

  late MockInventoryPendingDao pendingDao;
  late MockInventoryApi inventoryApi;
  late MockProductCacheDao productCacheDao;
  late MockInventoryCacheDao inventoryCacheDao;
  late MockDraftSaleDao draftSaleDao;
  late MockSalesApi salesApi;

  setUp(() {
    pendingDao = MockInventoryPendingDao();
    inventoryApi = MockInventoryApi();
    productCacheDao = MockProductCacheDao();
    inventoryCacheDao = MockInventoryCacheDao();
    draftSaleDao = MockDraftSaleDao();
    salesApi = MockSalesApi();
  });

  // ── Helpers ──────────────────────────────────────────────

  InventoryPendingQueueData fakeOp(
    int id,
    int productId, {
    int retryCount = 0,
  }) {
    return InventoryPendingQueueData(
      id: id,
      productId: productId,
      payload: '{"type":"ADJUSTMENT","quantity":5.0,"reason":"test"}',
      status: 'pending',
      createdAt: DateTime(2026, 5, 18),
      retryCount: retryCount,
    );
  }

  /// Crea un ConnectivityService con un stream controlado.
  Future<ConnectivityService> createConnectivityService({
    bool startOffline = true,
  }) async {
    final mockConnectivity = MockConnectivity();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(() => mockConnectivity.checkConnectivity()).thenAnswer(
      (_) async =>
          startOffline ? [ConnectivityResult.none] : [ConnectivityResult.wifi],
    );

    final service = ConnectivityService(connectivity: mockConnectivity);
    await service.initialize();
    return service;
  }

  void setupMocksForSync({
    List<InventoryPendingQueueData>? pendingOps,
    int draftCount = 0,
    List<ProductResponse> products = const [],
    List<InventoryResponse> inventory = const [],
  }) {
    when(
      () => pendingDao.getAllByStatus('pending'),
    ).thenAnswer((_) async => pendingOps ?? []);
    when(() => pendingDao.delete(any())).thenAnswer((_) async {});
    when(
      () => pendingDao.updateStatus(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => pendingDao.incrementRetry(any())).thenAnswer((_) async {});
    when(() => pendingDao.countByStatus(any())).thenAnswer((_) async => 0);
    when(
      () => draftSaleDao.countByStatus('draft'),
    ).thenAnswer((_) async => draftCount);
    when(() => salesApi.getProducts()).thenAnswer((_) async => products);
    when(() => productCacheDao.upsertAll(any())).thenAnswer((_) async {});
    when(() => inventoryApi.getLowStock()).thenAnswer((_) async => inventory);
    when(() => inventoryCacheDao.upsertAll(any())).thenAnswer((_) async {});
    when(() => inventoryApi.adjustStock(any(), any())).thenAnswer(
      (_) async => const InventoryResponse(
        productId: 1,
        productName: 'Test',
        currentStock: 10.0,
        minStockThreshold: 5.0,
      ),
    );
  }

  Future<void> triggerOnlineAndWait() async {
    connectivityController.add([ConnectivityResult.wifi]);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('SyncService', () {
    group('inventory queue processing', () {
      test('debe procesar operaciones pendientes en orden FIFO', () async {
        connectivityService = await createConnectivityService();
        setupMocksForSync(
          pendingOps: [fakeOp(1, 1), fakeOp(2, 2), fakeOp(3, 3)],
        );

        final syncService = SyncService(
          connectivity: connectivityService,
          inventoryPendingDao: pendingDao,
          inventoryApi: inventoryApi,
          productCacheDao: productCacheDao,
          inventoryCacheDao: inventoryCacheDao,
          draftSaleDao: draftSaleDao,
          salesApi: salesApi,
        );
        syncService.initialize();

        await triggerOnlineAndWait();

        verify(() => inventoryApi.adjustStock(1, any())).called(1);
        verify(() => inventoryApi.adjustStock(2, any())).called(1);
        verify(() => inventoryApi.adjustStock(3, any())).called(1);
        verify(() => pendingDao.delete(1)).called(1);
        verify(() => pendingDao.delete(2)).called(1);
        verify(() => pendingDao.delete(3)).called(1);
      });

      test('debe marcar operación fallida sin bloquear la cola', () async {
        connectivityService = await createConnectivityService();

        // Op 1 con retryCount=2: al fallar, incrementa a 3 y se marca como failed
        // Op 2 con retryCount=0: éxito normal
        setupMocksForSync(
          pendingOps: [fakeOp(1, 1, retryCount: 2), fakeOp(2, 2)],
        );

        // Override: op 1 falla con stock insuficiente
        when(
          () => inventoryApi.adjustStock(1, any()),
        ).thenThrow(const UnknownApiException('Stock insuficiente', 400));
        // Op 2 sigue usando el default de setupMocksForSync (éxito)

        final syncService = SyncService(
          connectivity: connectivityService,
          inventoryPendingDao: pendingDao,
          inventoryApi: inventoryApi,
          productCacheDao: productCacheDao,
          inventoryCacheDao: inventoryCacheDao,
          draftSaleDao: draftSaleDao,
          salesApi: salesApi,
        );
        syncService.initialize();

        await triggerOnlineAndWait();

        verify(
          () => pendingDao.updateStatus(1, 'failed', '400: Stock insuficiente'),
        ).called(1);
        verify(() => pendingDao.delete(2)).called(1);
        verifyNever(() => pendingDao.delete(1));
      });
    });

    group('draft count', () {
      test('debe actualizar draftCount después del sync', () async {
        connectivityService = await createConnectivityService();
        setupMocksForSync(draftCount: 3);

        final syncService = SyncService(
          connectivity: connectivityService,
          inventoryPendingDao: pendingDao,
          inventoryApi: inventoryApi,
          productCacheDao: productCacheDao,
          inventoryCacheDao: inventoryCacheDao,
          draftSaleDao: draftSaleDao,
          salesApi: salesApi,
        );
        syncService.initialize();

        await triggerOnlineAndWait();

        expect(syncService.draftCount.value, 3);
      });
    });

    group('lastSync', () {
      test('debe actualizar lastSync después del sync exitoso', () async {
        connectivityService = await createConnectivityService();
        setupMocksForSync();

        final syncService = SyncService(
          connectivity: connectivityService,
          inventoryPendingDao: pendingDao,
          inventoryApi: inventoryApi,
          productCacheDao: productCacheDao,
          inventoryCacheDao: inventoryCacheDao,
          draftSaleDao: draftSaleDao,
          salesApi: salesApi,
        );
        syncService.initialize();

        expect(syncService.lastSync.value, isNull);

        await triggerOnlineAndWait();

        expect(syncService.lastSync.value, isNotNull);
      });
    });
  });
}
