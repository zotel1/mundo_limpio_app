// Implementación concreta de ReceiptsRepository — directa al API.
//
// Delega directamente a ReceiptsApi sin lógica offline ni borradores.
// ADMIN-only, always-online por decisión de alcance (ver proposal).
//
// Métodos GET de historial:
// - getReceipts: delega a ReceiptsApi.getPurchases()
// - getReceiptById: delega a ReceiptsApi.getPurchaseById(id)
//
// TDD: GREEN — implementación puramente estructural, sin lógica

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/features/receipts/data/api/receipts_api.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/receipt.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';

/// Implementación de [ReceiptsRepository] con delegación directa al API.
///
/// Sin lógica offline/drafts porque el flujo de recibos es ADMIN-only
/// y se asume conectividad (decisión de alcance en proposal).
class ReceiptsRepositoryImpl implements ReceiptsRepository {
  final ReceiptsApi _api;

  /// Crea el repositorio con la instancia de [ReceiptsApi] inyectada.
  const ReceiptsRepositoryImpl({required ReceiptsApi api}) : _api = api;

  @override
  Future<Receipt> processReceipt(
    String imagePath, {
    CancelToken? cancelToken,
  }) async {
    final response = await _api.processReceipt(
      imagePath,
      cancelToken: cancelToken,
    );
    return response.toEntity();
  }

  @override
  Future<Purchase> confirmReceipt(
    ReceiptConfirmRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await _api.confirmReceipt(
      request,
      cancelToken: cancelToken,
    );
    return response.toEntity();
  }

  @override
  Future<List<Purchase>> getReceipts({CancelToken? cancelToken}) async {
    final response = await _api.getPurchases(cancelToken: cancelToken);
    return response.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Purchase> getReceiptById(int id, {CancelToken? cancelToken}) async {
    final response = await _api.getPurchaseById(id, cancelToken: cancelToken);
    return response.toEntity();
  }
}
