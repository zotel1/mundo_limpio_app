// Capa de comunicación HTTP para el módulo de Recibos OCR.
//
// Implementa las llamadas a los endpoints de recibos del backend:
// - POST /api/v1/receipts/process (multipart FormData)
// - POST /api/v1/receipts/confirm (JSON)
// - GET /api/v1/receipts (lista de compras)
// - GET /api/v1/receipts/{id} (detalle de compra)
//
// Recibe una instancia de Dio inyectada (sin crearla internamente)
// para permitir tests con mocks y compartir la configuración
// de ApiClient (base URL, timeouts, interceptors).
//
// TDD: GREEN — implementación para pasar los tests

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';

/// Cliente HTTP para los endpoints del módulo de Recibos OCR.
///
/// Cada método retorna su tipo correspondiente o lanza [ApiException]
/// (o subtipo) en caso de error.
///
/// Los errores HTTP se convierten con [ApiException.fromDioException]:
/// - 401/403 → [AuthException]
/// - 5xx → [ServerException]
/// - 0 (red) → [NetworkException]
///
/// Métodos GET de historial:
/// - [getPurchases]: lista de todas las compras
/// - [getPurchaseById]: detalle de una compra específica
class ReceiptsApi {
  final Dio _dio;

  /// Crea un [ReceiptsApi] con la instancia de [Dio] inyectada.
  ///
  /// [dio] debe estar configurado con la base URL y headers
  /// base (Content-Type, Accept) — ver ApiClient.create().
  const ReceiptsApi({required Dio dio}) : _dio = dio;

  /// Procesa una imagen de recibo con OCR en el backend.
  ///
  /// Endpoint: `POST /api/v1/receipts/process`
  /// Body: multipart FormData con el campo 'image'
  Future<ReceiptProcessResponse> processReceipt(
    String imagePath, {
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: 'receipt.jpg',
        ),
      });
      final response = await _dio.post(
        '/api/v1/receipts/process',
        data: formData,
        cancelToken: cancelToken,
      );
      return ReceiptProcessResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Confirma una compra desde recibo OCR en el backend.
  ///
  /// Endpoint: `POST /api/v1/receipts/confirm`
  /// Body: serialización JSON de [request]
  Future<PurchaseResponse> confirmReceipt(
    ReceiptConfirmRequest request, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/receipts/confirm',
        data: request.toJson(),
        cancelToken: cancelToken,
      );
      return PurchaseResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Obtiene la lista de compras (recibos confirmados).
  ///
  /// Endpoint: `GET /api/v1/receipts`
  Future<List<PurchaseResponse>> getPurchases({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/receipts',
        cancelToken: cancelToken,
      );
      final List<dynamic> data = response.data['content'] as List<dynamic>;
      return data
          .map(
            (json) => PurchaseResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Obtiene una compra (recibo confirmado) por su ID.
  ///
  /// Endpoint: `GET /api/v1/receipts/{id}`
  Future<PurchaseResponse> getPurchaseById(
    int id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/receipts/$id',
        cancelToken: cancelToken,
      );
      return PurchaseResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
