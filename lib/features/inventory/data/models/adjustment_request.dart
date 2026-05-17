// Modelo DTO para solicitar un ajuste de stock en el backend.
//
// Contiene el tipo de ajuste (enum AdjustmentType), la cantidad
// (double, signed para incrementos/decrementos) y el motivo.
// Se serializa/deserializa con json_serializable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:json_annotation/json_annotation.dart';

part 'adjustment_request.g.dart';

/// Tipo de ajuste de inventario.
///
/// - [ADJUSTMENT]: ajuste manual general.
/// - [BREAKAGE]: rotura o daño del producto.
/// - [RETURN]: devolución de cliente.
/// - [QUALITY_LOSS]: pérdida por control de calidad.
@JsonEnum()
enum AdjustmentType {
  @JsonValue('ADJUSTMENT')
  ADJUSTMENT,
  @JsonValue('BREAKAGE')
  BREAKAGE,
  @JsonValue('RETURN')
  RETURN,
  @JsonValue('QUALITY_LOSS')
  QUALITY_LOSS,
}

/// Request para ajustar el stock de un producto en el backend.
///
/// Mapea directamente el JSON esperado por el endpoint:
/// - `POST /api/v1/inventory/{productId}/adjust`
@JsonSerializable()
class AdjustmentRequest {
  /// Tipo de ajuste (enum serializado como string).
  final AdjustmentType type;

  /// Cantidad del ajuste. Positivo para incrementos,
  /// negativo para decrementos.
  final double quantity;

  /// Motivo del ajuste.
  final String reason;

  /// Crea un [AdjustmentRequest] con todos los campos requeridos.
  const AdjustmentRequest({
    required this.type,
    required this.quantity,
    required this.reason,
  });

  /// Construye un [AdjustmentRequest] desde un mapa JSON.
  factory AdjustmentRequest.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentRequestFromJson(json);

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$AdjustmentRequestToJson(this);
}
