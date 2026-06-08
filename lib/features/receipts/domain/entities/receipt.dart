// Entidad de dominio que representa un recibo procesado.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y enums puros.

import 'purchase.dart';

/// Recibo procesado por el sistema OCR.
///
/// Contiene los datos del recibo: identificador, nombre de archivo,
/// fecha detectada, estado y las compras asociadas.
class Receipt {
  /// ID único del recibo.
  final int id;

  /// Nombre del archivo de imagen del recibo.
  final String filename;

  /// Fecha de compra detectada por OCR (puede ser nula).
  final DateTime? detectedDate;

  /// Estado del procesamiento del recibo.
  final String status;

  /// Compras asociadas a este recibo.
  final List<Purchase> items;

  /// Crea un [Receipt] con todos los campos requeridos.
  const Receipt({
    required this.id,
    required this.filename,
    this.detectedDate,
    required this.status,
    required this.items,
  });

  /// Retorna una copia con los campos indicados reemplazados.
  Receipt copyWith({
    int? id,
    String? filename,
    DateTime? detectedDate,
    String? status,
    List<Purchase>? items,
  }) {
    return Receipt(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      detectedDate: detectedDate ?? this.detectedDate,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Receipt &&
        other.id == id &&
        other.filename == filename &&
        other.detectedDate == detectedDate &&
        other.status == status &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode =>
      Object.hash(id, filename, detectedDate, status, Object.hashAll(items));

  @override
  String toString() =>
      'Receipt(id: $id, filename: $filename, '
      'detectedDate: $detectedDate, status: $status, items: $items)';
}

bool _listEquals(List<dynamic>? a, List<dynamic>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
