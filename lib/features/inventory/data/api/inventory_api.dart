// Capa de comunicación HTTP para el módulo de Inventario.
//
// Implementa las llamadas a los endpoints de inventario del backend:
// - GET /api/v1/inventory/{productId}
// - GET /api/v1/inventory/low-stock
// - POST /api/v1/inventory/{productId}/adjust
//
// Recibe una instancia de Dio inyectada (sin crearla internamente)
// para permitir tests con mocks y compartir la configuración
// de ApiClient (base URL, timeouts, interceptors).
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';

/// Cliente HTTP para los endpoints del módulo de Inventario.
///
/// Cada método retorna su tipo correspondiente o lanza [ApiException]
/// (o subtipo) en caso de error.
///
/// Los errores HTTP se convierten con [ApiException.fromDioException]:
/// - 401/403 → [AuthException]
/// - 5xx → [ServerException]
/// - 0 (red) → [NetworkException]
class InventoryApi {
  final Dio _dio;

  /// Crea un [InventoryApi] con la instancia de [Dio] inyectada.
  ///
  /// [dio] debe estar configurado con la base URL y headers
  /// base (Content-Type, Accept) — ver ApiClient.create().
  const InventoryApi({required Dio dio}) : _dio = dio;

  /// Obtiene los datos de inventario de un producto específico.
  ///
  /// Endpoint: `GET /api/v1/inventory/{productId}`
  Future<InventoryResponse> getInventory(int productId) async {
    try {
      final response = await _dio.get('/api/v1/inventory/$productId');
      return InventoryResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Obtiene la lista de productos con stock bajo.
  ///
  /// Endpoint: `GET /api/v1/inventory/low-stock`
  ///
  /// El backend puede devolver:
  /// - `{content: [...]}` (respuesta paginada con wrapper)
  /// - `[]` (array vacío directamente)
  /// Ambos formatos se manejan para evitar crashes.
  Future<List<InventoryResponse>> getLowStock() async {
    try {
      final response = await _dio.get('/api/v1/inventory/low-stock');
      final rawData = response.data;
      final List<dynamic> data;
      if (rawData is List<dynamic>) {
        // El backend devolvió un array directamente (ej. vacío [])
        data = rawData;
      } else if (rawData is Map<String, dynamic> &&
          rawData.containsKey('content')) {
        // El backend devolvió un wrapper paginado {content: [...]}
        data = rawData['content'] as List<dynamic>;
      } else {
        data = [];
      }
      return data
          .map((e) => InventoryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Ajusta el stock de un producto en el backend.
  ///
  /// Endpoint: `POST /api/v1/inventory/{productId}/adjust`
  /// Body: serialización JSON de [request]
  Future<InventoryResponse> adjustStock(
    int productId,
    AdjustmentRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/inventory/$productId/adjust',
        data: request.toJson(),
      );
      return InventoryResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
