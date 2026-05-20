// Implementación concreta de ReceiptsRepository — directa al API.
//
// Delega directamente a ReceiptsApi sin lógica offline ni borradores.
// ADMIN-only, always-online por decisión de alcance (ver proposal).
//
// TDD: GREEN — implementación puramente estructural, sin lógica

import 'package:mundo_limpio_app/features/receipts/data/api/receipts_api.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';
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
  Future<ReceiptProcessResponse> processReceipt(String imagePath) =>
      _api.processReceipt(imagePath);

  @override
  Future<PurchaseResponse> confirmReceipt(ReceiptConfirmRequest request) =>
      _api.confirmReceipt(request);
}
