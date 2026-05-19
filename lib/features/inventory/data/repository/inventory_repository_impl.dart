// Implementación concreta de InventoryRepository — offline-aware.
//
// Orquesta online/offline según ConnectivityService:
// - Online GET: llama Api → cachea en InventoryCacheDao → retorna
// - Offline GET: lee desde InventoryCacheDao (cache hit/miss)
// - Online POST (adjustStock): llama Api directamente
// - Offline POST (adjustStock): encola en InventoryPendingDao → retorna
//   InventoryResponse.pending() como marcador
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'dart:convert';

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';
import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_cache_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_pending_dao.dart';

import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/domain/repository/inventory_repository.dart';

/// Implementación de [InventoryRepository] con soporte online/offline.
///
/// Recibe [InventoryApi] para HTTP, [ConnectivityService] para detectar
/// el estado de red, y dos DAOs de Drift para persistencia local
/// ([InventoryCacheDao] para cache de GETs, [InventoryPendingDao]
/// para cola de ajustes pendientes).
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryApi _inventoryApi;
  final ConnectivityService _connectivity;
  final InventoryCacheDao _inventoryCacheDao;
  final InventoryPendingDao _inventoryPendingDao;

  /// Crea el repositorio con todas las dependencias inyectadas.
  const InventoryRepositoryImpl({
    required InventoryApi inventoryApi,
    required ConnectivityService connectivity,
    required InventoryCacheDao inventoryCacheDao,
    required InventoryPendingDao inventoryPendingDao,
  }) : _inventoryApi = inventoryApi,
       _connectivity = connectivity,
       _inventoryCacheDao = inventoryCacheDao,
       _inventoryPendingDao = inventoryPendingDao;

  @override
  Future<InventoryResponse> getInventory(int productId) async {
    if (_connectivity.isOnline) {
      final response = await _inventoryApi.getInventory(productId);
      await _inventoryCacheDao.upsertAll([
        InventoryCacheData(
          productId: response.productId,
          productName: response.productName,
          currentStock: response.currentStock,
          minStockThreshold: response.minStockThreshold,
          updatedAt: DateTime.now(),
        ),
      ]);
      return response;
    }
    // offline: leer desde caché
    final cached = await _inventoryCacheDao.getByProductId(productId);
    if (cached == null) return _nullResponse();
    return InventoryResponse(
      productId: cached.productId,
      productName: cached.productName,
      currentStock: cached.currentStock,
      minStockThreshold: cached.minStockThreshold,
    );
  }

  /// Retorna un InventoryResponse nulo para el caso offline sin cache.
  ///
  /// Se usa un método privado porque es un detalle de implementación
  /// que no pertenece al contrato público.
  InventoryResponse _nullResponse() {
    return const InventoryResponse(
      productId: -1,
      productName: '',
      currentStock: 0,
      minStockThreshold: 0,
    );
  }

  @override
  Future<List<InventoryResponse>> getLowStock() async {
    if (_connectivity.isOnline) {
      final items = await _inventoryApi.getLowStock();
      await _inventoryCacheDao.upsertAll(
        items
            .map(
              (r) => InventoryCacheData(
                productId: r.productId,
                productName: r.productName,
                currentStock: r.currentStock,
                minStockThreshold: r.minStockThreshold,
                updatedAt: DateTime.now(),
              ),
            )
            .toList(),
      );
      return items;
    }
    // offline: leer desde caché
    final cached = await _inventoryCacheDao.getAll();
    return cached
        .map(
          (c) => InventoryResponse(
            productId: c.productId,
            productName: c.productName,
            currentStock: c.currentStock,
            minStockThreshold: c.minStockThreshold,
          ),
        )
        .toList();
  }

  @override
  Future<InventoryResponse> adjustStock(
    int productId,
    AdjustmentRequest request,
  ) async {
    if (_connectivity.isOnline) {
      return _inventoryApi.adjustStock(productId, request);
    }
    // offline: encolar como pendiente
    final payload = jsonEncode(request.toJson());
    await _inventoryPendingDao.insert(
      InventoryPendingQueueCompanion.insert(
        productId: productId,
        payload: payload,
      ),
    );
    return InventoryResponse.pending();
  }
}
