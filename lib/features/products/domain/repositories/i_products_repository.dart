import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';

abstract class IProductsRepository {
  Future<List<Product>> getAll({CancelToken? cancelToken});
  Future<List<Product>> getAllProducts({CancelToken? cancelToken});
  Future<Product> getById(int id, {CancelToken? cancelToken});
  Future<Product> getBySku(String sku, {CancelToken? cancelToken});
  Future<Product> create(Product product, {CancelToken? cancelToken});
  Future<Product> update(Product product, {CancelToken? cancelToken});
  Future<void> delete(int id, {CancelToken? cancelToken});
  Future<Product> reactivate(int id, {CancelToken? cancelToken});
}
