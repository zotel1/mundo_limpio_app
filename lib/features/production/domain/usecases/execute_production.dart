import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';

class ExecuteProduction {
  final IProductionRepository productionRepository;
  final IBulkProductRepository bulkProductRepository;

  ExecuteProduction(this.productionRepository, this.bulkProductRepository);

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

    // TDD: GREEN — stock validation against raw material repository
    final bulkProduct = await bulkProductRepository.getBulkProduct(request.bulkProductId);
    if (bulkProduct.stock < request.quantityUsed) {
      throw Exception(
        'Stock insuficiente de ${bulkProduct.name}. '
        'Stock disponible: ${bulkProduct.stock}, requerido: ${request.quantityUsed}',
      );
    }

    return await productionRepository.createProductionBatch(request);
  }
}
