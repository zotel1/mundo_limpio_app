// Modelo DTO para una línea de producto detectada por OCR.
//
// Representa cada ítem que el backend OCR extrae de la imagen
// del recibo. El campo `name` se mapea a `description` en la
// confirmación (ver ProductLineConfirmDto).
// Se serializa/deserializa con json_serializable.
//
// TDD: modelo puramente estructural — sin lógica que testear.
// Verificación vía build_runner + flutter analyze.

import 'package:json_annotation/json_annotation.dart';

part 'product_line_dto.g.dart';

/// Línea de producto detectada por el OCR del backend.
///
/// Respuesta del endpoint `POST /api/v1/receipts/process`
/// dentro del array `lines` de [ReceiptProcessResponse].
@JsonSerializable()
class ProductLineDto {
  /// Nombre del producto detectado por OCR.
  final String name;

  /// Cantidad detectada por OCR.
  final int quantity;

  /// Precio unitario detectado por OCR.
  final double unitPrice;

  /// Confianza de la detección OCR (0.0 a 1.0).
  final double confidence;

  /// ID del producto en el catálogo de bulk products (opcional).
  final int? bulkProductId;

  /// Crea un [ProductLineDto] con todos los campos requeridos.
  const ProductLineDto({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.confidence,
    this.bulkProductId,
  });

  /// Construye un [ProductLineDto] desde un mapa JSON.
  factory ProductLineDto.fromJson(Map<String, dynamic> json) =>
      _$ProductLineDtoFromJson(json);

  /// Serializa a mapa JSON.
  Map<String, dynamic> toJson() => _$ProductLineDtoToJson(this);
}
