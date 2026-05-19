// Implementación concreta de SalesRepository — offline-aware.
//
// Orquesta online/offline según ConnectivityService:
// - Online GET: llama API → cachea en Drift → retorna
// - Offline GET: lee desde caché Drift
// - Online POST: llama API directamente
// - Offline POST: guarda borrador en DraftSales
// - ConfirmDraft: lee borrador → llama API → marca confirmado
// - Batch TTL: caché de lotes offline expira a los 5 minutos
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';
import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/batch_cache_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/draft_sale_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/product_cache_dao.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/data/api/sales_api.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';

import 'draft_sale_extensions.dart';

/// Implementación de [SalesRepository] con soporte online/offline.
///
/// Recibe [SalesApi] para HTTP, [ConnectivityService] para detectar
/// el estado de red, y tres DAOs de Drift para persistencia local.
class SalesRepositoryImpl implements SalesRepository {
  final SalesApi _salesApi;
  final ConnectivityService _connectivity;
  final ProductCacheDao _productCacheDao;
  final BatchCacheDao _batchCacheDao;
  final DraftSaleDao _draftSaleDao;

  /// Crea el repositorio con todas las dependencias inyectadas.
  const SalesRepositoryImpl({
    required SalesApi salesApi,
    required ConnectivityService connectivity,
    required ProductCacheDao productCacheDao,
    required BatchCacheDao batchCacheDao,
    required DraftSaleDao draftSaleDao,
  }) : _salesApi = salesApi,
       _connectivity = connectivity,
       _productCacheDao = productCacheDao,
       _batchCacheDao = batchCacheDao,
       _draftSaleDao = draftSaleDao;

  @override
  Future<List<ProductResponse>> getProducts() async {
    if (_connectivity.isOnline) {
      final products = await _salesApi.getProducts();
      await _productCacheDao.upsertAll(
        products
            .map((p) => ProductCacheData(
                  id: p.id,
                  name: p.name,
                  updatedAt: DateTime.now(),
                ))
            .toList(),
      );
      return products;
    }
    // offline: leer desde caché
    final cached = await _productCacheDao.getAll();
    return cached
        .map((c) => ProductResponse(id: c.id, name: c.name))
        .toList();
  }

  @override
  Future<List<ProductionBatchResponse>> getBatchesByProduct(
    int productId,
  ) async {
    if (_connectivity.isOnline) {
      final batches = await _salesApi.getBatchesByProduct(productId);
      // limpia caché viejo antes de guardar el nuevo
      await _batchCacheDao.deleteByProductId(productId);
      await _batchCacheDao.upsertAll(
        batches
            .map((b) => BatchCacheData(
                  id: b.id,
                  productId: productId,
                  currentStock: b.currentStock,
                  updatedAt: DateTime.now(),
                ))
            .toList(),
      );
      return batches;
    }
    // offline: leer caché con validación de TTL (5 min)
    final cached = await _batchCacheDao.getByProductId(productId);
    if (cached.isEmpty) return [];
    final age = DateTime.now().difference(cached.first.updatedAt);
    if (age.inMinutes > 5) return []; // expirado
    return cached
        .map((c) => ProductionBatchResponse(
              id: c.id,
              productId: c.productId,
              currentStock: c.currentStock,
            ))
        .toList();
  }

  @override
  Future<SaleResponse> createSale(SaleRequest request) async {
    if (_connectivity.isOnline) {
      return _salesApi.createSale(request);
    }
    // offline: guardar como borrador
    await _draftSaleDao.insert(
      DraftSalesCompanion.insert(
        productId: request.productId,
        productName: '',
        batchId: 0,
        quantity: request.quantity,
        unitPrice: 0,
      ),
    );
    return SaleResponse.draft();
  }

  @override
  Future<SaleResponse> confirmDraft(int draftId) async {
    final draft = await _draftSaleDao.getById(draftId);
    if (draft == null) {
      throw ApiException('Borrador no encontrado', 404);
    }
    final request = draft.toRequest();
    final response = await _salesApi.createSale(request);
    await _draftSaleDao.updateStatus(draftId, 'confirmed');
    return response;
  }

  @override
  Future<List<DraftSale>> getDrafts() {
    return _draftSaleDao.getAllByStatus('draft');
  }
}
