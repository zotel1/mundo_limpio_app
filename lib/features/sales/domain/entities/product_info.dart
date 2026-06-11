// Entidad de dominio con los datos mínimos de un producto.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y equatable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:equatable/equatable.dart';

/// Datos mínimos de un producto usados en el contrato del repositorio.
///
/// Contiene [id] y [name], los campos necesarios para
/// seleccionar un producto al crear una venta.
class ProductInfo extends Equatable {
  /// ID único del producto.
  final int id;

  /// Nombre del producto.
  final String name;

  /// Crea un [ProductInfo] con todos los campos requeridos.
  const ProductInfo({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
