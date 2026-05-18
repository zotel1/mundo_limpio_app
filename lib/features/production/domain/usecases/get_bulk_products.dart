import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';

class GetBulkProducts {
  final IBulkProductRepository repository;

  GetBulkProducts(this.repository);

  Future<List<BulkProduct>> execute() async {
    return await repository.getBulkProducts();
  }
}
