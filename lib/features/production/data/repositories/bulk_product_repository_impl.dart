import 'package:dio/dio.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/data/models/bulk_product_model.dart';

class BulkProductRepositoryImpl implements IBulkProductRepository {
  final Dio _dio;

  BulkProductRepositoryImpl(this._dio);

  @override
  Future<List<BulkProduct>> getBulkProducts({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        '/api/v1/bulk-products',
        cancelToken: cancelToken,
      );
      final List<dynamic> data = response.data['content'] as List<dynamic>;
      return data
          .map(
            (json) => BulkProductModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<BulkProduct> getBulkProduct(int id, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        '/api/v1/bulk-products/$id',
        cancelToken: cancelToken,
      );
      return BulkProductModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<BulkProduct> createBulkProduct(
    BulkProduct product, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/bulk-products',
        data: {
          'name': product.name,
          'currentStockLiters': product.currentStockLiters,
          'costPerLiter': product.costPerLiter,
          'conversionRatio': product.conversionRatio,
          'active': product.active,
        },
        cancelToken: cancelToken,
      );
      return BulkProductModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<BulkProduct> updateBulkProduct(
    BulkProduct product, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/bulk-products/${product.id}',
        data: {
          'name': product.name,
          'currentStockLiters': product.currentStockLiters,
          'costPerLiter': product.costPerLiter,
          'conversionRatio': product.conversionRatio,
          'active': product.active,
        },
        cancelToken: cancelToken,
      );
      return BulkProductModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteBulkProduct(int id, {CancelToken? cancelToken}) async {
    try {
      await _dio.delete('/api/v1/bulk-products/$id', cancelToken: cancelToken);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
