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

import 'package:mundo_limpio_app/features/receipts/data/api/receipts_api.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/product_line_confirm_dto.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/receipt.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/receipt_confirmation.dart';
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
  Future<Receipt> processReceipt(String imagePath) async {
    final response = await _api.processReceipt(imagePath);
    return response.toEntity();
  }

  @override
  Future<Purchase> confirmReceipt(ReceiptConfirmation data) async {
    final request = ReceiptConfirmRequest(
      imageUrl: data.imageUrl,
      supplierName: data.supplierName,
      purchaseDate: data.purchaseDate,
      lines: data.lines
          .map(
            (l) => ProductLineConfirmDto(
              description: l.description,
              quantity: l.quantity,
              unitPrice: l.unitPrice,
              bulkProductId: l.bulkProductId,
            ),
          )
          .toList(),
    );
    final response = await _api.confirmReceipt(request);
    return response.toEntity();
  }

  @override
  Future<List<Purchase>> getReceipts() async {
    final response = await _api.getPurchases();
    return response.map((e) => e.toEntity()).toList();
  }

  @override
  Future<Purchase> getReceiptById(int id) async {
    final response = await _api.getPurchaseById(id);
    return response.toEntity();
  }
}
