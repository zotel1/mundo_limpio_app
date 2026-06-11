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

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';
import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_cache_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_pending_dao.dart';

import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart'
    as dto;
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/adjustment.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/stock_item.dart';
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
  Future<StockItem> getInventory(
    int productId, {
    CancelToken? cancelToken,
  }) async {
    if (_connectivity.isOnline) {
      final response = await _inventoryApi.getInventory(
        productId,
        cancelToken: cancelToken,
      );
      await _inventoryCacheDao.upsertAll([
        InventoryCacheData(
          productId: response.productId,
          productName: response.productName,
          currentStock: response.currentStock,
          minStockThreshold: response.minStockThreshold,
          updatedAt: DateTime.now(),
        ),
      ]);
      return response.toEntity();
    }
    // offline: leer desde caché
    final cached = await _inventoryCacheDao.getByProductId(productId);
    if (cached == null) return _nullResponse();
    return StockItem(
      productId: cached.productId,
      productName: cached.productName,
      currentStock: cached.currentStock,
      minStockThreshold: cached.minStockThreshold,
    );
  }

  /// Retorna un StockItem nulo para el caso offline sin cache.
  StockItem _nullResponse() {
    return const StockItem(
      productId: -1,
      productName: '',
      currentStock: 0,
      minStockThreshold: 0,
    );
  }

  @override
  Future<List<StockItem>> getLowStock({CancelToken? cancelToken}) async {
    if (_connectivity.isOnline) {
      final items = await _inventoryApi.getLowStock(cancelToken: cancelToken);
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
      return items.map((e) => e.toEntity()).toList();
    }
    // offline: leer desde caché
    final cached = await _inventoryCacheDao.getAll();
    return cached
        .map(
          (c) => StockItem(
            productId: c.productId,
            productName: c.productName,
            currentStock: c.currentStock,
            minStockThreshold: c.minStockThreshold,
          ),
        )
        .toList();
  }

  @override
  Future<StockItem> adjustStock(
    int productId,
    Adjustment adjustment, {
    CancelToken? cancelToken,
  }) async {
    if (_connectivity.isOnline) {
      final request = dto.AdjustmentRequest(
        type: _mapDomainTypeToDto(adjustment.type),
        quantity: adjustment.quantity,
        reason: adjustment.reason,
      );
      final response = await _inventoryApi.adjustStock(
        productId,
        request,
        cancelToken: cancelToken,
      );
      return response.toEntity();
    }
    // offline: encolar como pendiente
    final request = dto.AdjustmentRequest(
      type: _mapDomainTypeToDto(adjustment.type),
      quantity: adjustment.quantity,
      reason: adjustment.reason,
    );
    final payload = jsonEncode(request.toJson());
    await _inventoryPendingDao.insert(
      InventoryPendingQueueCompanion.insert(
        productId: productId,
        payload: payload,
      ),
    );
    return const StockItem(
      productId: -1,
      productName: '',
      currentStock: 0,
      minStockThreshold: 0,
    );
  }

  /// Mapea [AdjustmentType] del dominio al enum DTO.
  dto.AdjustmentType _mapDomainTypeToDto(AdjustmentType type) {
    switch (type) {
      case AdjustmentType.adjustment:
        return dto.AdjustmentType.ADJUSTMENT;
      case AdjustmentType.breakage:
        return dto.AdjustmentType.BREAKAGE;
      case AdjustmentType.return_:
        return dto.AdjustmentType.RETURN;
      case AdjustmentType.qualityLoss:
        return dto.AdjustmentType.QUALITY_LOSS;
    }
  }
}
