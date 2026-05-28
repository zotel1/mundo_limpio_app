import 'package:dio/dio.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/data/models/bulk_product_model.dart';

class BulkProductRepositoryImpl implements IBulkProductRepository {
  final Dio _dio;

  BulkProductRepositoryImpl(this._dio);

  @override
  Future<List<BulkProduct>> getBulkProducts() async {
    try {
      final response = await _dio.get('/api/v1/bulk-products');
      final List<dynamic> data = response.data;
      return data
          .map((json) => BulkProductModel.fromJson(json).toEntity())
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  @override
  Future<BulkProduct> getBulkProduct(int id) async {
    try {
      final response = await _dio.get('/api/v1/bulk-products/$id');
      return BulkProductModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  @override
  Future<BulkProduct> createBulkProduct(BulkProduct product) async {
    try {
      final response = await _dio.post(
        '/api/v1/bulk-products',
        data: {
          'name': product.name,
          'currentStockLiters': product.currentStockLiters,
          'costperLiter': product.costPerLiter,
          if (product.conversionRatio != null)
            'conversionRatio': product.conversionRatio,
          'active': product.active,
        },
      );
      return BulkProductModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  @override
  Future<BulkProduct> updateBulkProduct(BulkProduct product) async {
    try {
      final response = await _dio.put(
        '/api/v1/bulk-products/${product.id}',
        data: {
          'name': product.name,
          'currentStockLiters': product.currentStockLiters,
          'costperLiter': product.costPerLiter,
          if (product.conversionRatio != null)
            'conversionRatio': product.conversionRatio,
          'active': product.active,
        },
      );
      return BulkProductModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  @override
  Future<void> deleteBulkProduct(int id) async {
    try {
      await _dio.delete('/api/v1/bulk-products/$id');
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }
}
