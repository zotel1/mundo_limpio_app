// Entidad de dominio para un ajuste de inventario.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y enums puros.

/// Tipo de ajuste de inventario.
///
/// Versión pura del dominio (sin anotaciones de serialización).
enum AdjustmentType {
  /// Ajuste manual general.
  adjustment,

  /// Rotura o daño del producto.
  breakage,

  /// Devolución de cliente.
  return_,

  /// Pérdida por control de calidad.
  qualityLoss,
}

/// Ajuste de stock solicitado sobre un producto.
///
/// Contiene el tipo de ajuste, la cantidad (positiva o negativa)
/// y el motivo del ajuste.
class Adjustment {
  /// Tipo de ajuste.
  final AdjustmentType type;

  /// Cantidad del ajuste. Positivo para incrementos,
  /// negativo para decrementos.
  final double quantity;

  /// Motivo del ajuste.
  final String reason;

  /// Crea un [Adjustment] con todos los campos requeridos.
  const Adjustment({
    required this.type,
    required this.quantity,
    required this.reason,
  });

  /// Retorna una copia con los campos indicados reemplazados.
  Adjustment copyWith({
    AdjustmentType? type,
    double? quantity,
    String? reason,
  }) {
    return Adjustment(
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Adjustment &&
        other.type == type &&
        other.quantity == quantity &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(type, quantity, reason);

  @override
  String toString() =>
      'Adjustment(type: $type, quantity: $quantity, reason: $reason)';
}
