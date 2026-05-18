import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';

class ExecuteProduction {
  final IProductionRepository repository;

  ExecuteProduction(this.repository);

  Future<ProductionBatch> execute(ProductionBatchRequest request) async {
    if (request.finishedProductId <= 0) {
      throw Exception('El ID del producto terminado debe ser mayor a 0');
    }
    if (request.bulkProductId <= 0) {
      throw Exception('El ID del producto a granel debe ser mayor a 0');
    }
    if (request.quantityUsed <= 0) {
      throw Exception('La cantidad usada debe ser mayor a 0');
    }
    return await repository.createProductionBatch(request);
  }
}
