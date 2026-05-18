import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';

class ProductionBatchRequest {
  final int finishedProductId;
  final int bulkProductId;
  final double quantityUsed;

  ProductionBatchRequest({
    required this.finishedProductId,
    required this.bulkProductId,
    required this.quantityUsed,
  });
}

abstract class IProductionRepository {
  Future<List<ProductionBatch>> getProductionBatches();
  Future<ProductionBatch> getProductionBatch(int id);
  Future<ProductionBatch> createProductionBatch(ProductionBatchRequest request);
}
