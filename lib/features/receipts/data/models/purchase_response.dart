// Modelo DTO para la respuesta de compra confirmada.
//
// Contiene todos los datos de la compra persistida en el backend
// incluyendo ítems, total y metadatos.
// Se serializa/deserializa con json_serializable.
//
// TDD: modelo puramente estructural — sin lógica que testear.
// Verificación vía build_runner + flutter analyze.

import 'package:json_annotation/json_annotation.dart';

import 'package:mundo_limpio_app/features/receipts/data/models/purchase_item_response.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';

part 'purchase_response.g.dart';

/// Respuesta del backend con los datos de la compra confirmada.
///
/// Mapea el JSON del endpoint `POST /api/v1/receipts/confirm`.
@JsonSerializable(explicitToJson: true)
class PurchaseResponse {
  /// ID único de la compra.
  final int id;

  /// URL pública de la imagen del recibo.
  final String imageUrl;

  /// Nombre del proveedor.
  final String supplierName;

  /// Fecha de la compra.
  final DateTime purchaseDate;

  /// Monto total de la compra.
  final double total;

  /// Lista de ítems incluidos en esta compra.
  final List<PurchaseItemResponse> items;

  /// Crea un [PurchaseResponse] con todos los campos requeridos.
  const PurchaseResponse({
    required this.id,
    required this.imageUrl,
    required this.supplierName,
    required this.purchaseDate,
    required this.total,
    required this.items,
  });

  /// Construye un [PurchaseResponse] desde un mapa JSON.
  factory PurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$PurchaseResponseFromJson(json);

  /// Serializa a mapa JSON.
  Map<String, dynamic> toJson() => _$PurchaseResponseToJson(this);
}

/// Extensión para convertir [PurchaseResponse] a entidad de dominio [Purchase].
extension PurchaseResponseMapper on PurchaseResponse {
  /// Convierte este DTO en un [Purchase] del dominio.
  Purchase toEntity() => Purchase(
    id: id,
    supplierName: supplierName,
    total: total,
    createdAt: purchaseDate,
  );
}
