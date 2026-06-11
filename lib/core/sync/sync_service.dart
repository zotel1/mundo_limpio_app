// Servicio de sincronización al reconectar.
//
// Responsabilidades:
// - Procesar cola de inventory_pending_queue en orden FIFO al reconectar
// - Refrescar cachés de productos e inventario
// - Notificar cantidad de drafts pendientes
// - Exponer ValueNotifiers para que la UI muestre estado de sync
//
// Las ventas NO se auto-sincronizan — el operador las confirma manualmente
// desde la pantalla de "Ventas Pendientes".
//
// TDD: GREEN — implementación mínima para pasar sync_service_test.dart

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../connectivity/connectivity_service.dart';
import '../drift/app_database.dart';
import '../drift/daos/draft_sale_dao.dart';
import '../drift/daos/inventory_cache_dao.dart';
import '../drift/daos/inventory_pending_dao.dart';
import '../drift/daos/product_cache_dao.dart';
import '../network/api_exception.dart';
import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/sales/data/api/sales_api.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';

/// Orquesta la sincronización de datos offline al reconectar.
///
/// Escucha [ConnectivityService] y dispara el pipeline de sync:
/// 1. Procesa cola de inventory (FIFO, auto-sync)
/// 2. Refresca cachés (productos, inventario)
/// 3. Actualiza contadores de notificación
class SyncService {
  final ConnectivityService _connectivity;
  final InventoryPendingDao _inventoryPendingDao;
  final InventoryApi _inventoryApi;
  final ProductCacheDao _productCacheDao;
  final InventoryCacheDao _inventoryCacheDao;
  final DraftSaleDao _draftSaleDao;
  final SalesApi _salesApi;

  bool _isSyncing = false;

  /// Cantidad de drafts (ventas offline) pendientes de confirmar.
  final ValueNotifier<int> draftCount = ValueNotifier(0);

  /// Fecha y hora de la última sincronización exitosa.
  final ValueNotifier<DateTime?> lastSync = ValueNotifier(null);

  SyncService({
    required ConnectivityService connectivity,
    required InventoryPendingDao inventoryPendingDao,
    required InventoryApi inventoryApi,
    required ProductCacheDao productCacheDao,
    required InventoryCacheDao inventoryCacheDao,
    required DraftSaleDao draftSaleDao,
    required SalesApi salesApi,
  }) : _connectivity = connectivity,
       _inventoryPendingDao = inventoryPendingDao,
       _inventoryApi = inventoryApi,
       _productCacheDao = productCacheDao,
       _inventoryCacheDao = inventoryCacheDao,
       _draftSaleDao = draftSaleDao,
       _salesApi = salesApi;

  /// Inicializa el servicio: escucha cambios de conectividad y
  /// ejecuta sync inmediato si ya está online.
  void initialize() {
    _connectivity.addListener(_onConnectivityChanged);
    if (_connectivity.isOnline) _sync();
  }

  void _onConnectivityChanged() {
    if (_connectivity.isOnline) _sync();
  }

  Future<void> _sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _processInventoryQueue();
      await _refreshCaches();
      await _updateDraftCount();
      lastSync.value = DateTime.now();
    } finally {
      _isSyncing = false;
    }
  }

  /// Procesa la cola de ajustes de inventario en orden FIFO.
  ///
  /// Cada operación exitosa se elimina de la cola.
  /// Las fallidas se marcan como 'failed' con el mensaje de error,
  /// sin bloquear el procesamiento de las siguientes.
  Future<void> _processInventoryQueue() async {
    final pending = await _inventoryPendingDao.getAllByStatus('pending');
    for (final op in pending) {
      try {
        final request = AdjustmentRequest.fromJson(
          jsonDecode(op.payload) as Map<String, dynamic>,
        );
        await _inventoryApi.adjustStock(op.productId, request);
        await _inventoryPendingDao.delete(op.id);
      } on ApiException catch (e) {
        final currentRetry = op.retryCount;
        await _inventoryPendingDao.incrementRetry(op.id);
        final newRetryCount = currentRetry + 1;

        if (newRetryCount >= 3) {
          await _inventoryPendingDao.updateStatus(
            op.id,
            'failed',
            '${e.code}: ${e.message}',
          );
        } else {
          // Backoff exponencial antes del próximo reintento
          await Future.delayed(
            Duration(seconds: pow(2, newRetryCount - 1).toInt()),
          );
        }
      } catch (e) {
        await _inventoryPendingDao.updateStatus(op.id, 'failed', e.toString());
      }
    }
  }

  /// Refresca los cachés locales desde el backend.
  Future<void> _refreshCaches() async {
    // Productos
    final products = await _salesApi.getProducts();
    final now = DateTime.now();
    await _productCacheDao.upsertAll(
      products.map<ProductCacheData>((p) => _productToCache(p, now)).toList(),
    );

    // Inventario (low stock)
    final lowStock = await _inventoryApi.getLowStock();
    await _inventoryCacheDao.upsertAll(
      lowStock
          .map<InventoryCacheData>((i) => _inventoryToCache(i, now))
          .toList(),
    );
  }

  /// Actualiza el contador de drafts pendientes.
  Future<void> _updateDraftCount() async {
    final count = await _draftSaleDao.countByStatus('draft');
    draftCount.value = count;
  }

  /// Libera recursos.
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    draftCount.dispose();
    lastSync.dispose();
  }
}

// ─── Mappers ──────────────────────────────────────────────────

ProductCacheData _productToCache(ProductResponse product, DateTime now) {
  return ProductCacheData(
    id: product.id,
    name: product.name,
    updatedAt: now,
    active: true,
  );
}

InventoryCacheData _inventoryToCache(InventoryResponse inv, DateTime now) {
  return InventoryCacheData(
    productId: inv.productId,
    productName: inv.productName,
    currentStock: inv.currentStock,
    minStockThreshold: inv.minStockThreshold,
    updatedAt: now,
  );
}
