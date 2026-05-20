// Modelo DTO para un ítem de compra confirmada.
//
// Representa cada línea de la compra ya persistida en el backend
// como respuesta del endpoint de confirmación.
// Se serializa/deserializa con json_serializable.
//
// TDD: modelo puramente estructural — sin lógica que testear.
// Verificación vía build_runner + flutter analyze.

import 'package:json_annotation/json_annotation.dart';

part 'purchase_item_response.g.dart';

/// Ítem individual dentro de una compra confirmada.
///
/// Mapea un elemento del array `items` en la respuesta del endpoint:
/// `POST /api/v1/receipts/confirm`.
@JsonSerializable()
class PurchaseItemResponse {
  /// ID único del ítem de compra.
  final int id;

  /// Descripción del producto.
  final String description;

  /// Cantidad comprada.
  final int quantity;

  /// Precio unitario del producto.
  final double unitPrice;

  /// Precio total de esta línea (quantity × unitPrice).
  final double totalPrice;

  /// ID del producto en el catálogo de bulk products (opcional).
  final int? bulkProductId;

  /// Crea un [PurchaseItemResponse] con todos los campos requeridos.
  const PurchaseItemResponse({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.bulkProductId,
  });

  /// Construye un [PurchaseItemResponse] desde un mapa JSON.
  factory PurchaseItemResponse.fromJson(Map<String, dynamic> json) =>
      _$PurchaseItemResponseFromJson(json);

  /// Serializa a mapa JSON.
  Map<String, dynamic> toJson() => _$PurchaseItemResponseToJson(this);
}
