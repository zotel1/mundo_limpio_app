import 'package:dio/dio.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/data/models/production_batch_model.dart';

class ProductionRepositoryImpl implements IProductionRepository {
  final Dio _dio;

  ProductionRepositoryImpl(this._dio);

  @override
  Future<List<ProductionBatch>> getProductionBatches() async {
    try {
      final response = await _dio.get('/api/v1/production-batches');
      final List<dynamic> data = response.data['content'] as List<dynamic>;
      return data
          .map(
            (json) => ProductionBatchModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  @override
  Future<ProductionBatch> getProductionBatch(int id) async {
    try {
      final response = await _dio.get('/api/v1/production-batches/$id');
      return ProductionBatchModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  @override
  Future<ProductionBatch> createProductionBatch(
    ProductionBatchRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/production-batches',
        data: {
          'productId': request.finishedProductId,
          'bulkProductId': request.bulkProductId,
          'rawQuantityUsed': request.quantityUsed,
        },
      );
      return ProductionBatchModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }
}
