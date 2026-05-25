import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';

abstract class IProductsRepository {
  Future<List<Product>> getAll();
  Future<List<Product>> getAllProducts();
  Future<Product> getById(int id);
  Future<Product> getBySku(String sku);
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> delete(int id);
  Future<Product> reactivate(int id);
}
