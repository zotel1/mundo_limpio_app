// Modelo DTO para un ítem dentro de una venta (respuesta del backend).
//
// Representa cada línea de una venta, incluyendo batch, cantidad,
// precio unitario y costo unitario.
// Se serializa/deserializa con json_serializable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:json_annotation/json_annotation.dart';

part 'sale_item_response.g.dart';

/// Ítem individual dentro de una venta.
///
/// Mapea un elemento del array `items` en la respuesta del endpoint:
/// - `GET /api/v1/sales/:id`
/// - `POST /api/v1/sales`
@JsonSerializable()
class SaleItemResponse {
  /// ID del lote (batch) del producto vendido.
  final int batchId;

  /// ID del producto vendido.
  final int productId;

  /// Nombre del producto en el momento de la transacción.
  final String productName;

  /// Cantidad vendida (admite decimales para fracciones).
  final double quantity;

  /// Precio unitario de venta en el momento de la transacción.
  final double unitPrice;

  /// Costo unitario del producto en el momento de la transacción.
  final double unitCost;

  /// Crea un [SaleItemResponse] con todos los campos requeridos.
  const SaleItemResponse({
    required this.batchId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
  });

  /// Construye un [SaleItemResponse] desde un mapa JSON.
  factory SaleItemResponse.fromJson(Map<String, dynamic> json) =>
      _$SaleItemResponseFromJson(json);

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$SaleItemResponseToJson(this);
}
