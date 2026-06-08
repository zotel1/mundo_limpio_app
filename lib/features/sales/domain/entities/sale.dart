// Entidad de dominio que representa una venta.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y enums puros.

import 'sale_item.dart';

/// Venta realizada en el sistema.
///
/// Contiene el ID, ítems vendidos, total, fecha de creación
/// y estado de la venta.
class Sale {
  /// ID único de la venta.
  final int id;

  /// Lista de ítems incluidos en esta venta.
  final List<SaleItem> items;

  /// Monto total de la venta.
  final double total;

  /// Fecha y hora de creación.
  final DateTime createdAt;

  /// Estado de la venta (ej: 'completed', 'cancelled').
  final String status;

  /// Crea un [Sale] con todos los campos requeridos.
  const Sale({
    required this.id,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.status,
  });

  /// Retorna una copia con los campos indicados reemplazados.
  Sale copyWith({
    int? id,
    List<SaleItem>? items,
    double? total,
    DateTime? createdAt,
    String? status,
  }) {
    return Sale(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale &&
        other.id == id &&
        other.total == total &&
        other.createdAt == createdAt &&
        other.status == status &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode =>
      Object.hash(id, Object.hashAll(items), total, createdAt, status);

  @override
  String toString() =>
      'Sale(id: $id, total: $total, createdAt: $createdAt, '
      'status: $status, items: $items)';
}

bool _listEquals(List<dynamic>? a, List<dynamic>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
