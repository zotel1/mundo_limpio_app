import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';

class CreateBulkProduct {
  final IBulkProductRepository repository;

  CreateBulkProduct(this.repository);

  Future<BulkProduct> execute(BulkProduct product) async {
    return await repository.createBulkProduct(product);
  }
}
