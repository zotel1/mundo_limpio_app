// Modelo DTO para confirmar una línea de producto.
//
// DIFERENCIA CLAVE con ProductLineDto: usa `description`
// en lugar de `name` como nombre del campo.
// El backend espera `description` en el request de confirmación.
// Se serializa/deserializa con json_serializable.
//
// TDD: modelo puramente estructural — sin lógica que testear.
// Verificación vía build_runner + flutter analyze.

import 'package:json_annotation/json_annotation.dart';

part 'product_line_confirm_dto.g.dart';

/// Línea de producto a confirmar en el backend.
///
/// Enviada dentro del array `lines` en el endpoint
/// `POST /api/v1/receipts/confirm`.
@JsonSerializable()
class ProductLineConfirmDto {
  /// Descripción del producto (mapeada desde ProductLineDto.name).
  final String description;

  /// Cantidad del producto.
  final int quantity;

  /// Precio unitario del producto.
  final double unitPrice;

  /// ID del producto en el catálogo de bulk products (opcional).
  final int? bulkProductId;

  /// Crea un [ProductLineConfirmDto] con todos los campos requeridos.
  const ProductLineConfirmDto({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.bulkProductId,
  });

  /// Construye un [ProductLineConfirmDto] desde un mapa JSON.
  factory ProductLineConfirmDto.fromJson(Map<String, dynamic> json) =>
      _$ProductLineConfirmDtoFromJson(json);

  /// Serializa a mapa JSON.
  Map<String, dynamic> toJson() => _$ProductLineConfirmDtoToJson(this);
}
