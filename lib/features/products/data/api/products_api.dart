// Capa de comunicación HTTP para el módulo de Productos (admin CRUD).
//
// Implementa las 8 llamadas a los endpoints de productos del backend:
// - GET /api/v1/products (list active)
// - GET /api/v1/products/all (list all)
// - GET /api/v1/products/{id} (by id)
// - GET /api/v1/products/sku/{sku} (by sku)
// - POST /api/v1/products (create)
// - PUT /api/v1/products/{id} (update)
// - DELETE /api/v1/products/{id} (soft delete)
// - PATCH /api/v1/products/{id}/reactivate (reactivate)
//
// Recibe una instancia de Dio inyectada (sin crearla internamente)
// para permitir tests con mocks y compartir la configuración
// de ApiClient (base URL, timeouts, interceptors).
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/products/data/models/product_model.dart';

/// Cliente HTTP para los endpoints de administración de productos.
///
/// Cada método retorna su tipo correspondiente o lanza [ApiException]
/// (o subtipo) en caso de error.
///
/// Los errores HTTP se convierten con [ApiException.fromStatusCode]:
/// - 401/403 → [AuthException]
/// - 5xx → [ServerException]
/// - 0 (red) → [NetworkException]
class ProductsApi {
  final Dio _dio;

  /// Crea un [ProductsApi] con la instancia de [Dio] inyectada.
  const ProductsApi({required Dio dio}) : _dio = dio;

  /// Obtiene la lista de productos activos.
  ///
  /// Endpoint: `GET /api/v1/products`
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _dio.get('/api/v1/products');
      final data = response.data['content'] as List<dynamic>;
      return data
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Obtiene la lista de todos los productos (activos e inactivos).
  ///
  /// Endpoint: `GET /api/v1/products/all`
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await _dio.get('/api/v1/products/all');
      final data = response.data['content'] as List<dynamic>;
      return data
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Obtiene un producto por su ID.
  ///
  /// Endpoint: `GET /api/v1/products/{id}`
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _dio.get('/api/v1/products/$id');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Obtiene un producto por su SKU.
  ///
  /// Endpoint: `GET /api/v1/products/sku/{sku}`
  Future<ProductModel> getProductBySku(String sku) async {
    try {
      final response = await _dio.get('/api/v1/products/sku/$sku');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Crea un nuevo producto.
  ///
  /// Endpoint: `POST /api/v1/products`
  /// [data] debe contener los campos del producto (sku, name, minPrice, active).
  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/v1/products', data: data);
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Actualiza un producto existente.
  ///
  /// Endpoint: `PUT /api/v1/products/{id}`
  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/v1/products/$id', data: data);
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Elimina (soft delete) un producto.
  ///
  /// Endpoint: `DELETE /api/v1/products/{id}`
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/api/v1/products/$id');
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Reactiva un producto previamente eliminado.
  ///
  /// Endpoint: `PATCH /api/v1/products/{id}/reactivate`
  Future<ProductModel> reactivateProduct(int id) async {
    try {
      final response = await _dio.patch('/api/v1/products/$id/reactivate');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }
}
