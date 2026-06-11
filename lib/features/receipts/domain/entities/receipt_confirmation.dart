// Entidad de dominio que agrupa los datos para confirmar un recibo.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y equatable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:equatable/equatable.dart';

import 'product_line_confirm.dart';

/// Datos de confirmación de un recibo OCR.
///
/// Contiene [imageUrl], [supplierName], [purchaseDate] y
/// la lista de [lines] (productos confirmados).
class ReceiptConfirmation extends Equatable {
  /// URL pública de la imagen del recibo.
  final String imageUrl;

  /// Nombre del proveedor (corregido por el admin).
  final String supplierName;

  /// Fecha de compra en formato "yyyy-MM-dd".
  final String purchaseDate;

  /// Líneas de productos confirmadas.
  final List<ProductLineConfirm> lines;

  /// Crea un [ReceiptConfirmation] con todos los campos requeridos.
  const ReceiptConfirmation({
    required this.imageUrl,
    required this.supplierName,
    required this.purchaseDate,
    required this.lines,
  });

  @override
  List<Object?> get props => [imageUrl, supplierName, purchaseDate, lines];
}
