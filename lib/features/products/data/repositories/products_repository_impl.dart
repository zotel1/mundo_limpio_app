// Implementación del repositorio de productos.
//
// Wrapper sobre ProductsApi que convierte modelos de datos a entidades
// del dominio y maneja errores de API.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/products/data/api/products_api.dart';
import 'package:mundo_limpio_app/features/products/data/models/product_model.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/domain/repositories/i_products_repository.dart';

class ProductsRepositoryImpl implements IProductsRepository {
  final ProductsApi _api;

  ProductsRepositoryImpl({required ProductsApi api}) : _api = api;

  @override
  Future<List<Product>> getAll() async {
    try {
      final models = await _api.getProducts();
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final models = await _api.getAllProducts();
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch all products: $e');
    }
  }

  @override
  Future<Product> getById(int id) async {
    try {
      final model = await _api.getProductById(id);
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch product $id: $e');
    }
  }

  @override
  Future<Product> getBySku(String sku) async {
    try {
      final model = await _api.getProductBySku(sku);
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch product by sku $sku: $e');
    }
  }

  @override
  Future<Product> create(Product product) async {
    try {
      final model = ProductModel(
        id: product.id,
        sku: product.sku,
        name: product.name,
        minPrice: product.minPrice,
        active: product.active,
      );
      final created = await _api.createProduct(model.toJson());
      return created.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<Product> update(Product product) async {
    try {
      final model = ProductModel(
        id: product.id,
        sku: product.sku,
        name: product.name,
        minPrice: product.minPrice,
        active: product.active,
      );
      final updated = await _api.updateProduct(product.id, model.toJson());
      return updated.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update product ${product.id}: $e');
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _api.deleteProduct(id);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete product $id: $e');
    }
  }

  @override
  Future<Product> reactivate(int id) async {
    try {
      final model = await _api.reactivateProduct(id);
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to reactivate product $id: $e');
    }
  }
}
