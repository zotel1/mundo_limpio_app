// Modelo DTO para confirmar una compra desde recibo.
//
// Enviado al backend con los datos revisados y corregidos
// por el admin. purchaseDate en formato "yyyy-MM-dd".
// Se serializa/deserializa con json_serializable.
//
// TDD: modelo puramente estructural — sin lógica que testear.
// Verificación vía build_runner + flutter analyze.

import 'package:json_annotation/json_annotation.dart';

import 'package:mundo_limpio_app/features/receipts/data/models/product_line_confirm_dto.dart';

part 'receipt_confirm_request.g.dart';

/// Request para confirmar una compra desde recibo OCR.
///
/// Mapea el JSON esperado por el endpoint
/// `POST /api/v1/receipts/confirm`.
@JsonSerializable(explicitToJson: true)
class ReceiptConfirmRequest {
  /// URL pública de la imagen del recibo en el backend.
  final String imageUrl;

  /// Nombre del proveedor (corregido por el admin).
  final String supplierName;

  /// Fecha de compra en formato "yyyy-MM-dd".
  final String purchaseDate;

  /// Líneas de productos confirmadas.
  final List<ProductLineConfirmDto> lines;

  /// Crea un [ReceiptConfirmRequest] con todos los campos requeridos.
  const ReceiptConfirmRequest({
    required this.imageUrl,
    required this.supplierName,
    required this.purchaseDate,
    required this.lines,
  });

  /// Construye un [ReceiptConfirmRequest] desde un mapa JSON.
  factory ReceiptConfirmRequest.fromJson(Map<String, dynamic> json) =>
      _$ReceiptConfirmRequestFromJson(json);

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$ReceiptConfirmRequestToJson(this);
}
