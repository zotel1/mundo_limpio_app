// Modelo DTO para la respuesta de una venta del backend.
//
// Contiene los datos completos de una venta incluyendo
// sus ítems, total y metadatos.
// Se serializa/deserializa con json_serializable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:json_annotation/json_annotation.dart';

import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';

part 'sale_response.g.dart';

/// Respuesta del backend con los datos de una venta.
///
/// Mapea directamente el JSON de los endpoints:
/// - `GET /api/v1/sales/:id`
/// - `POST /api/v1/sales`
@JsonSerializable(explicitToJson: true)
class SaleResponse {
  /// ID único de la venta.
  final int id;

  /// Monto total de la venta (suma de quantity * unitPrice de cada item).
  final double totalAmount;

  /// Fecha y hora ISO 8601 de creación de la venta.
  final DateTime createdAt;

  /// Lista de ítems incluidos en esta venta.
  final List<SaleItemResponse> items;

  /// Crea un [SaleResponse] con todos los campos requeridos.
  const SaleResponse({
    required this.id,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  /// Construye un [SaleResponse] desde un mapa JSON.
  factory SaleResponse.fromJson(Map<String, dynamic> json) =>
      _$SaleResponseFromJson(json);

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$SaleResponseToJson(this);
}
