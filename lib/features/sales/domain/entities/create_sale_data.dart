// Entidad de dominio que agrupa los datos para crear una venta.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y equatable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:equatable/equatable.dart';

/// Datos necesarios para crear una venta.
///
/// Agrupa [productId] y [quantity] como objeto de valor
/// inmutable que se pasa al repositorio.
class CreateSaleData extends Equatable {
  /// ID del producto a vender.
  final int productId;

  /// Cantidad del producto a vender.
  final double quantity;

  /// Crea un [CreateSaleData] con todos los campos requeridos.
  const CreateSaleData({required this.productId, required this.quantity});

  @override
  List<Object?> get props => [productId, quantity];
}
