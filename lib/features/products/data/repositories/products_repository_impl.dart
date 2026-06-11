// Implementación del repositorio de productos con soporte offline.
//
// Online: llama a la API → cachea en Drift → retorna entidades.
// Offline: lee desde caché Drift; si está vacío, lanza ApiException.
// Escrituras: siempre pasan por la API; en éxito, cachean el resultado.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';
import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/product_cache_dao.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/products/data/api/products_api.dart';
import 'package:mundo_limpio_app/features/products/data/models/product_model.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/domain/repositories/i_products_repository.dart';

/// Implementación de [IProductsRepository] con soporte offline.
///
/// Sigue el patrón read-through cache:
/// - GET online: API + cache-prime → entidades
/// - GET offline: solo caché Drift → entidades (o error si vacío)
/// - POST/PUT/DELETE: siempre API → cache-prime en éxito
class ProductsRepositoryImpl implements IProductsRepository {
  final ProductsApi _api;
  final ConnectivityService _connectivity;
  final ProductCacheDao _cacheDao;

  /// Crea el repositorio con todas las dependencias inyectadas.
  ProductsRepositoryImpl({
    required ProductsApi api,
    required ConnectivityService connectivityService,
    required ProductCacheDao productCacheDao,
  }) : _api = api,
       _connectivity = connectivityService,
       _cacheDao = productCacheDao;

  /// Convierte [ProductModel] (de API) a [ProductCacheData] (Drift).
  ProductCacheData _toCacheData(ProductModel model) => ProductCacheData(
    id: model.id,
    name: model.name,
    sku: model.sku,
    minPrice: model.minPrice,
    active: model.active,
    updatedAt: DateTime.now(),
  );

  /// Convierte [ProductCacheData] (Drift) a [Product] (entidad de dominio).
  Product _cacheToEntity(ProductCacheData cache) => Product(
    id: cache.id,
    sku: cache.sku,
    name: cache.name,
    minPrice: cache.minPrice,
    active: cache.active,
  );

  /// Lanza [ApiException] cuando no hay conexión ni datos cacheados.
  Never _throwOfflineError() {
    throw const UnknownApiException('Sin conexión y sin datos en caché', 0);
  }

  @override
  Future<List<Product>> getAll({CancelToken? cancelToken}) async {
    if (_connectivity.isOnline) {
      try {
        final models = await _api.getProducts(cancelToken: cancelToken);
        await _cacheDao.upsertAll(models.map(_toCacheData).toList());
        return models.map((m) => m.toEntity()).toList();
      } on ApiException {
        rethrow;
      } catch (e) {
        throw Exception('Failed to fetch products: $e');
      }
    }
    final cached = await _cacheDao.getAll();
    if (cached.isEmpty) _throwOfflineError();
    return cached.map(_cacheToEntity).toList();
  }

  @override
  Future<List<Product>> getAllProducts({CancelToken? cancelToken}) async {
    if (_connectivity.isOnline) {
      try {
        final models = await _api.getAllProducts(cancelToken: cancelToken);
        await _cacheDao.upsertAll(models.map(_toCacheData).toList());
        return models.map((m) => m.toEntity()).toList();
      } on ApiException {
        rethrow;
      } catch (e) {
        throw Exception('Failed to fetch all products: $e');
      }
    }
    final cached = await _cacheDao.getAll();
    if (cached.isEmpty) _throwOfflineError();
    return cached.map(_cacheToEntity).toList();
  }

  @override
  Future<Product> getById(int id, {CancelToken? cancelToken}) async {
    if (_connectivity.isOnline) {
      try {
        final model = await _api.getProductById(id, cancelToken: cancelToken);
        await _cacheDao.upsert(_toCacheData(model));
        return model.toEntity();
      } on ApiException {
        rethrow;
      } catch (e) {
        throw Exception('Failed to fetch product $id: $e');
      }
    }
    final cached = await _cacheDao.getById(id);
    if (cached == null) _throwOfflineError();
    return _cacheToEntity(cached);
  }

  @override
  Future<Product> getBySku(String sku, {CancelToken? cancelToken}) async {
    try {
      final model = await _api.getProductBySku(sku, cancelToken: cancelToken);
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch product by sku $sku: $e');
    }
  }

  @override
  Future<Product> create(Product product, {CancelToken? cancelToken}) async {
    try {
      final model = ProductModel(
        id: product.id,
        sku: product.sku,
        name: product.name,
        minPrice: product.minPrice,
        active: product.active,
      );
      final created = await _api.createProduct(
        model.toJson(),
        cancelToken: cancelToken,
      );
      await _cacheDao.upsert(_toCacheData(created));
      return created.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<Product> update(Product product, {CancelToken? cancelToken}) async {
    try {
      final model = ProductModel(
        id: product.id,
        sku: product.sku,
        name: product.name,
        minPrice: product.minPrice,
        active: product.active,
      );
      final updated = await _api.updateProduct(
        product.id,
        model.toJson(),
        cancelToken: cancelToken,
      );
      await _cacheDao.upsert(_toCacheData(updated));
      return updated.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update product ${product.id}: $e');
    }
  }

  @override
  Future<void> delete(int id, {CancelToken? cancelToken}) async {
    try {
      await _api.deleteProduct(id, cancelToken: cancelToken);
      final cached = await _cacheDao.getById(id);
      if (cached != null) {
        await _cacheDao.upsert(cached.copyWith(active: false));
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete product $id: $e');
    }
  }

  @override
  Future<Product> reactivate(int id, {CancelToken? cancelToken}) async {
    try {
      final model = await _api.reactivateProduct(id, cancelToken: cancelToken);
      await _cacheDao.upsert(_toCacheData(model));
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to reactivate product $id: $e');
    }
  }
}
