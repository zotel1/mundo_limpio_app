// Entidad de dominio con los datos de un lote de producción.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y equatable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:equatable/equatable.dart';

/// Datos de un lote de producción usados en el contrato del repositorio.
///
/// Contiene [id], [productId] y [quantity] (stock actual del lote).
class BatchInfo extends Equatable {
  /// ID único del lote de producción.
  final int id;

  /// ID del producto al que pertenece este lote.
  final int productId;

  /// Cantidad disponible en este lote.
  final double quantity;

  /// Crea un [BatchInfo] con todos los campos requeridos.
  const BatchInfo({
    required this.id,
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [id, productId, quantity];
}
