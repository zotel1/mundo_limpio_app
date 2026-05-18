import 'package:dio/dio.dart';
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
      final List<dynamic> data = response.data;
      return data
          .map((json) => ProductionBatchModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch production batches: $e');
    }
  }

  @override
  Future<ProductionBatch> getProductionBatch(int id) async {
    try {
      final response = await _dio.get('/api/v1/production-batches/$id');
      return ProductionBatchModel.fromJson(response.data).toEntity();
    } catch (e) {
      throw Exception('Failed to fetch production batch $id: $e');
    }
  }

  @override
  Future<ProductionBatch> createProductionBatch(
      ProductionBatchRequest request) async {
    try {
      final response = await _dio.post('/api/v1/production-batches', data: {
        'finished_product_id': request.finishedProductId,
        'bulk_product_id': request.bulkProductId,
        'quantity_used': request.quantityUsed,
      });
      return ProductionBatchModel.fromJson(response.data).toEntity();
    } catch (e) {
      throw Exception('Failed to create production batch: $e');
    }
  }
}
