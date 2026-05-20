// Contrato abstracto del repositorio de Recibos OCR.
//
// Define la interfaz que la capa de presentación (Provider)
// usa para procesar y confirmar recibos, sin depender
// de implementaciones concretas de red.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo tipos de Dart puro y modelos del dominio.
//
// TDD: GREEN — interfaz puramente estructural, sin lógica

import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';

/// Repositorio de Recibos OCR.
///
/// Métodos:
/// - [processReceipt]: envía imagen al OCR y retorna datos detectados
/// - [confirmReceipt]: confirma una compra desde recibo OCR
///
/// ADMIN-only, always-online — sin lógica offline/drafts.
abstract class ReceiptsRepository {
  /// Procesa una imagen de recibo con OCR en el backend.
  ///
  /// [imagePath]: ruta local del archivo de imagen.
  /// Retorna [ReceiptProcessResponse] con proveedor, fecha y líneas.
  /// Lanza [ApiException] en caso de error de red o procesamiento.
  Future<ReceiptProcessResponse> processReceipt(String imagePath);

  /// Confirma una compra desde recibo OCR en el backend.
  ///
  /// [request]: datos revisados de la compra a confirmar.
  /// Retorna [PurchaseResponse] con los datos de la compra confirmada.
  /// Lanza [ApiException] en caso de error de validación o red.
  Future<PurchaseResponse> confirmReceipt(ReceiptConfirmRequest request);
}
