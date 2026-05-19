// Modelo DTO para la respuesta de inventario del backend.
//
// Contiene los datos de stock de un producto: ID, nombre,
// stock actual y umbral mínimo.
// Se serializa/deserializa con json_serializable.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:json_annotation/json_annotation.dart';

part 'inventory_response.g.dart';

/// Respuesta del backend con los datos de inventario de un producto.
///
/// Mapea directamente el JSON de los endpoints:
/// - `GET /api/v1/inventory/{productId}`
/// - `GET /api/v1/inventory/low-stock`
/// - `POST /api/v1/inventory/{productId}/adjust`
@JsonSerializable()
class InventoryResponse {
  /// ID del producto.
  final int productId;

  /// Nombre del producto.
  final String productName;

  /// Stock actual del producto (admite decimales).
  final double currentStock;

  /// Umbral mínimo de stock para considerar bajo inventario.
  final double minStockThreshold;

  /// Crea un [InventoryResponse] con todos los campos requeridos.
  const InventoryResponse({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minStockThreshold,
  });

  /// Crea un [InventoryResponse] que representa un ajuste pendiente
  /// (encolado offline, aún no sincronizado con el backend).
  ///
  /// Retorna productId=-1 como marcador para que el Provider pueda
  /// detectar que este ajuste NO fue confirmado en el backend.
  /// Es análogo a [SaleResponse.draft()] del módulo de Ventas.
  factory InventoryResponse.pending() {
    return const InventoryResponse(
      productId: -1,
      productName: '',
      currentStock: 0,
      minStockThreshold: 0,
    );
  }

  /// Construye un [InventoryResponse] desde un mapa JSON.
  factory InventoryResponse.fromJson(Map<String, dynamic> json) =>
      _$InventoryResponseFromJson(json);

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$InventoryResponseToJson(this);
}
