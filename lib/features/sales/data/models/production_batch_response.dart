// Modelo DTO para la respuesta de lotes de producción del backend.
//
// Contiene los datos mínimos necesarios para calcular
// el stock disponible de un lote al crear una venta.
// Serialización vía json_serializable (fromJson/toJson generados).
//
// TDD: GREEN — conversión a @JsonSerializable, reemplaza fromJson manual

import 'package:json_annotation/json_annotation.dart';

part 'production_batch_response.g.dart';

/// Respuesta del backend con los datos básicos de un lote de producción.
///
/// Mapea el JSON del endpoint:
/// - `GET /api/v1/production-batches/product/{productId}`
@JsonSerializable()
class ProductionBatchResponse {
  /// ID único del lote de producción.
  final int id;

  /// ID del producto al que pertenece este lote.
  final int productId;

  /// Stock actual disponible en este lote.
  final double currentStock;

  /// Crea un [ProductionBatchResponse] con todos los campos requeridos.
  const ProductionBatchResponse({
    required this.id,
    required this.productId,
    required this.currentStock,
  });

  /// Construye un [ProductionBatchResponse] desde un mapa JSON.
  factory ProductionBatchResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductionBatchResponseFromJson(json);

  /// Serializa a mapa JSON.
  Map<String, dynamic> toJson() => _$ProductionBatchResponseToJson(this);
}
