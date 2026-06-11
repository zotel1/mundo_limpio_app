// Contrato abstracto del repositorio de Recibos OCR.
//
// Define la interfaz que la capa de presentación (Provider)
// usa para procesar y confirmar recibos, sin depender
// de implementaciones concretas de red.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo tipos de Dart puro y modelos del dominio.
//
// Métodos GET de historial:
// - [getReceipts]: obtiene la lista de compras confirmadas
// - [getReceiptById]: obtiene una compra específica por ID
//
// TDD: GREEN — interfaz puramente estructural, sin lógica

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';

import '../entities/receipt.dart';
import '../entities/purchase.dart';

/// Repositorio de Recibos OCR.
///
/// Métodos:
/// - [processReceipt]: envía imagen al OCR y retorna datos detectados
/// - [confirmReceipt]: confirma una compra desde recibo OCR
/// - [getReceipts]: obtiene lista de compras confirmadas
/// - [getReceiptById]: obtiene una compra específica por ID
///
/// ADMIN-only, always-online — sin lógica offline/drafts.
abstract class ReceiptsRepository {
  /// Procesa una imagen de recibo con OCR en el backend.
  ///
  /// [imagePath]: ruta local del archivo de imagen.
  /// Retorna [Receipt] con los datos procesados.
  /// Lanza [ApiException] en caso de error de red o procesamiento.
  Future<Receipt> processReceipt(String imagePath, {CancelToken? cancelToken});

  /// Confirma una compra desde recibo OCR en el backend.
  ///
  /// [request]: datos revisados de la compra a confirmar.
  /// Retorna [Purchase] con los datos de la compra confirmada.
  /// Lanza [ApiException] en caso de error de validación o red.
  Future<Purchase> confirmReceipt(
    ReceiptConfirmRequest request, {
    CancelToken? cancelToken,
  });

  /// Obtiene la lista de compras (recibos confirmados) desde el backend.
  ///
  /// Endpoint: `GET /api/v1/receipts`
  /// Retorna una lista de [Purchase].
  /// Lanza [ApiException] en caso de error de red.
  Future<List<Purchase>> getReceipts({CancelToken? cancelToken});

  /// Obtiene una compra (recibo confirmado) por su ID.
  ///
  /// [id]: ID único de la compra.
  /// Retorna [Purchase] con los datos de la compra.
  /// Lanza [ApiException] si el ID no existe o hay error de red.
  Future<Purchase> getReceiptById(int id, {CancelToken? cancelToken});
}
