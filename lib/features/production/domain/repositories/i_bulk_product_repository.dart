import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';

abstract class IBulkProductRepository {
  Future<List<BulkProduct>> getBulkProducts();
  Future<BulkProduct> getBulkProduct(int id);
  Future<BulkProduct> createBulkProduct(BulkProduct product);
  Future<BulkProduct> updateBulkProduct(BulkProduct product);
  Future<void> deleteBulkProduct(int id);
}
