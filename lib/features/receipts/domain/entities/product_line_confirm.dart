// Entidad de dominio para una línea de producto a confirmar.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y equatable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:equatable/equatable.dart';

/// Línea de producto a confirmar en un recibo.
///
/// Contiene [description], [quantity], [unitPrice] y un
/// [bulkProductId] opcional para vincular con el catálogo.
class ProductLineConfirm extends Equatable {
  /// Descripción del producto.
  final String description;

  /// Cantidad del producto.
  final int quantity;

  /// Precio unitario del producto.
  final double unitPrice;

  /// ID del producto en el catálogo de bulk products (opcional).
  final int? bulkProductId;

  /// Crea un [ProductLineConfirm] con todos los campos requeridos.
  const ProductLineConfirm({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.bulkProductId,
  });

  @override
  List<Object?> get props => [description, quantity, unitPrice, bulkProductId];
}
