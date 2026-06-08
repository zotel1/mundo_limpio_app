// Entidad de dominio que representa una compra confirmada.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y enums puros.

/// Compra confirmada en el sistema.
///
/// Contiene ID único, nombre del proveedor, monto total
/// y fecha de creación de la compra.
class Purchase {
  /// ID único de la compra.
  final int id;

  /// Nombre del proveedor.
  final String supplierName;

  /// Monto total de la compra.
  final double total;

  /// Fecha y hora de creación de la compra.
  final DateTime createdAt;

  /// Crea un [Purchase] con todos los campos requeridos.
  const Purchase({
    required this.id,
    required this.supplierName,
    required this.total,
    required this.createdAt,
  });

  /// Retorna una copia con los campos indicados reemplazados.
  Purchase copyWith({
    int? id,
    String? supplierName,
    double? total,
    DateTime? createdAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Purchase &&
        other.id == id &&
        other.supplierName == supplierName &&
        other.total == total &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, supplierName, total, createdAt);

  @override
  String toString() =>
      'Purchase(id: $id, supplierName: $supplierName, '
      'total: $total, createdAt: $createdAt)';
}
