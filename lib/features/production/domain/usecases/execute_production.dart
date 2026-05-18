import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';

class ExecuteProduction {
  final IProductionRepository repository;

  ExecuteProduction(this.repository);

  Future<ProductionBatch> execute(ProductionBatchRequest request) async {
    return await repository.createProductionBatch(request);
  }
}
