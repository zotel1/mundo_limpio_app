// Modelo DTO para crear una venta en el backend.
//
// Contiene los datos necesarios para POST /api/v1/sales.
// Se serializa/deserializa con json_serializable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:json_annotation/json_annotation.dart';

part 'sale_request.g.dart';

/// Request para crear una venta en el backend.
///
/// Mapea directamente el JSON esperado por el endpoint:
/// - `POST /api/v1/sales`
@JsonSerializable()
class SaleRequest {
  /// ID del producto a vender.
  final int productId;

  /// Cantidad del producto (admite decimales para fracciones).
  final double quantity;

  /// Crea un [SaleRequest] con todos los campos requeridos.
  const SaleRequest({
    required this.productId,
    required this.quantity,
  });

  /// Construye un [SaleRequest] desde un mapa JSON.
  factory SaleRequest.fromJson(Map<String, dynamic> json) =>
      _$SaleRequestFromJson(json);

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$SaleRequestToJson(this);
}
