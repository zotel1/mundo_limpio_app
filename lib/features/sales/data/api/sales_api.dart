// Capa de comunicación HTTP para el módulo de Ventas.
//
// Implementa las llamadas a los endpoints de ventas del backend:
// - POST /api/v1/sales
// - GET /api/v1/products
// - GET /api/v1/production-batches/product/{productId}
//
// Recibe una instancia de Dio inyectada (sin crearla internamente)
// para permitir tests con mocks y compartir la configuración
// de ApiClient (base URL, timeouts, interceptors).
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';

/// Cliente HTTP para los endpoints del módulo de Ventas.
///
/// Cada método retorna su tipo correspondiente o lanza [ApiException]
/// (o subtipo) en caso de error.
///
/// Los errores HTTP se convierten con [ApiException.fromStatusCode]:
/// - 401/403 → [AuthException]
/// - 5xx → [ServerException]
/// - 0 (red) → [NetworkException]
class SalesApi {
  final Dio _dio;

  /// Crea un [SalesApi] con la instancia de [Dio] inyectada.
  ///
  /// [dio] debe estar configurado con la base URL y headers
  /// base (Content-Type, Accept) — ver ApiClient.create().
  const SalesApi({required Dio dio}) : _dio = dio;

  /// Crea una nueva venta en el backend.
  ///
  /// Endpoint: `POST /api/v1/sales`
  /// Body: serialización JSON de [request]
  Future<SaleResponse> createSale(SaleRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/sales',
        data: request.toJson(),
      );
      return SaleResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Obtiene la lista de productos disponibles.
  ///
  /// Endpoint: `GET /api/v1/products`
  Future<List<ProductResponse>> getProducts() async {
    try {
      final response = await _dio.get('/api/v1/products');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }

  /// Obtiene los lotes de producción de un producto específico.
  ///
  /// Endpoint: `GET /api/v1/production-batches/product/{productId}`
  Future<List<ProductionBatchResponse>> getBatchesByProduct(
      int productId) async {
    try {
      final response = await _dio.get(
        '/api/v1/production-batches/product/$productId',
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) =>
              ProductionBatchResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }
}
