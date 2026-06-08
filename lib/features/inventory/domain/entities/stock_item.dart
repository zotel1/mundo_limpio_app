// Entidad de dominio que representa el stock de un producto.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y enums puros.

/// Stock actual de un producto en el inventario.
///
/// Contiene el ID del producto, su nombre, el stock actual
/// y el umbral mínimo para considerar bajo inventario.
class StockItem {
  /// ID del producto.
  final int productId;

  /// Nombre del producto.
  final String productName;

  /// Stock actual del producto (admite decimales).
  final double currentStock;

  /// Umbral mínimo de stock.
  final double minStockThreshold;

  /// Crea un [StockItem] con todos los campos requeridos.
  const StockItem({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minStockThreshold,
  });

  /// Retorna una copia con los campos indicados reemplazados.
  StockItem copyWith({
    int? productId,
    String? productName,
    double? currentStock,
    double? minStockThreshold,
  }) {
    return StockItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockItem &&
        other.productId == productId &&
        other.productName == productName &&
        other.currentStock == currentStock &&
        other.minStockThreshold == minStockThreshold;
  }

  @override
  int get hashCode =>
      Object.hash(productId, productName, currentStock, minStockThreshold);

  @override
  String toString() =>
      'StockItem(productId: $productId, productName: $productName, '
      'currentStock: $currentStock, minStockThreshold: $minStockThreshold)';
}
