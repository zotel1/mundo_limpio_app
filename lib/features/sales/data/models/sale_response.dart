// Modelo DTO para la respuesta de una venta del backend.
//
// Contiene los datos completos de una venta incluyendo
// sus ítems, total y metadatos.
// Se serializa/deserializa con json_serializable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:json_annotation/json_annotation.dart';

import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/sale.dart';

part 'sale_response.g.dart';

/// Respuesta del backend con los datos de una venta.
///
/// Mapea directamente el JSON de los endpoints:
/// - `GET /api/v1/sales/:id`
/// - `POST /api/v1/sales`
@JsonSerializable(explicitToJson: true)
class SaleResponse {
  /// ID único de la venta.
  final int id;

  /// Monto total de la venta (suma de quantity * unitPrice de cada item).
  final double totalAmount;

  /// Fecha y hora ISO 8601 de creación de la venta.
  final DateTime createdAt;

  /// Lista de ítems incluidos en esta venta.
  final List<SaleItemResponse> items;

  /// Crea un [SaleResponse] con todos los campos requeridos.
  const SaleResponse({
    required this.id,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  /// Crea un [SaleResponse] que representa un borrador (venta offline).
  ///
  /// Retorna id=-1, totalAmount=0, items=[] para que el Provider
  /// pueda distinguir que esta venta fue guardada localmente y no
  /// confirmada en el backend. El [createdAt] es el momento actual.
  ///
  /// TDD: GREEN — implementación mínima para pasar los tests
  factory SaleResponse.draft() {
    return SaleResponse(
      id: -1,
      totalAmount: 0,
      createdAt: DateTime.now(),
      items: const [],
    );
  }

  /// Construye un [SaleResponse] desde un mapa JSON.
  factory SaleResponse.fromJson(Map<String, dynamic> json) =>
      _$SaleResponseFromJson(json);

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$SaleResponseToJson(this);
}

/// Extensión para convertir [SaleResponse] a entidad de dominio [Sale].
extension SaleResponseMapper on SaleResponse {
  /// Convierte este DTO en un [Sale] del dominio.
  Sale toEntity() => Sale(
    id: id,
    items: items.map((e) => e.toEntity()).toList(),
    total: totalAmount,
    createdAt: createdAt,
    status: '', // SaleResponse no tiene status, se asigna vacío
  );
}
