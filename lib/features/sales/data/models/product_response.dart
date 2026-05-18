// Modelo DTO para la respuesta de productos del backend.
//
// Contiene los datos mínimos necesarios para el selector
// de productos en el formulario de venta.
// Serialización vía json_serializable (fromJson/toJson generados).
//
// TDD: GREEN — conversión a @JsonSerializable, reemplaza fromJson manual

import 'package:json_annotation/json_annotation.dart';

part 'product_response.g.dart';

/// Respuesta del backend con los datos básicos de un producto.
///
/// Mapea el JSON del endpoint:
/// - `GET /api/v1/products`
@JsonSerializable()
class ProductResponse {
  /// ID único del producto.
  final int id;

  /// Nombre del producto.
  final String name;

  /// Crea un [ProductResponse] con todos los campos requeridos.
  const ProductResponse({required this.id, required this.name});

  /// Construye un [ProductResponse] desde un mapa JSON.
  factory ProductResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductResponseFromJson(json);

  /// Serializa a mapa JSON.
  Map<String, dynamic> toJson() => _$ProductResponseToJson(this);
}
