import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';

abstract class IBulkProductRepository {
  Future<List<BulkProduct>> getBulkProducts({CancelToken? cancelToken});
  Future<BulkProduct> getBulkProduct(int id, {CancelToken? cancelToken});
  Future<BulkProduct> createBulkProduct(
    BulkProduct product, {
    CancelToken? cancelToken,
  });
  Future<BulkProduct> updateBulkProduct(
    BulkProduct product, {
    CancelToken? cancelToken,
  });
  Future<void> deleteBulkProduct(int id, {CancelToken? cancelToken});
}
