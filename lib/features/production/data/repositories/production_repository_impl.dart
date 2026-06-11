import 'package:dio/dio.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/data/models/production_batch_model.dart';

class ProductionRepositoryImpl implements IProductionRepository {
  final Dio _dio;

  ProductionRepositoryImpl(this._dio);

  @override
  Future<List<ProductionBatch>> getProductionBatches({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/production-batches',
        cancelToken: cancelToken,
      );
      final List<dynamic> data = response.data['content'] as List<dynamic>;
      return data
          .map(
            (json) => ProductionBatchModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ProductionBatch> getProductionBatch(
    int id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/production-batches/$id',
        cancelToken: cancelToken,
      );
      return ProductionBatchModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ProductionBatch> createProductionBatch(
    ProductionBatchRequest request, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/production-batches',
        data: {
          'productId': request.finishedProductId,
          'bulkProductId': request.bulkProductId,
          'rawQuantityUsed': request.quantityUsed,
        },
        cancelToken: cancelToken,
      );
      return ProductionBatchModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
