// Entidad de dominio que representa un ítem dentro de una venta.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y enums puros.

/// Ítem individual dentro de una venta.
///
/// Contiene el ID del producto, nombre, cantidad vendida
/// y precio unitario en el momento de la transacción.
class SaleItem {
  /// ID del producto vendido.
  final int productId;

  /// Nombre del producto en el momento de la transacción.
  final String productName;

  /// Cantidad vendida (admite decimales para fracciones).
  final double quantity;

  /// Precio unitario de venta.
  final double unitPrice;

  /// Crea un [SaleItem] con todos los campos requeridos.
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  /// Retorna una copia con los campos indicados reemplazados.
  SaleItem copyWith({
    int? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
  }) {
    return SaleItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleItem &&
        other.productId == productId &&
        other.productName == productName &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice;
  }

  @override
  int get hashCode => Object.hash(productId, productName, quantity, unitPrice);

  @override
  String toString() =>
      'SaleItem(productId: $productId, productName: $productName, '
      'quantity: $quantity, unitPrice: $unitPrice)';
}
