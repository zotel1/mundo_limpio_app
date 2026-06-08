// Modelo DTO para la respuesta del procesamiento OCR.
//
// Contiene los datos extraídos por el backend desde la imagen
// del recibo: proveedor, fecha, líneas y URL de la imagen.
// Se serializa/deserializa con json_serializable.
//
// TDD: modelo puramente estructural — sin lógica que testear.
// Verificación vía build_runner + flutter analyze.

import 'package:json_annotation/json_annotation.dart';

import 'package:mundo_limpio_app/features/receipts/data/models/product_line_dto.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/receipt.dart';

part 'receipt_process_response.g.dart';

/// Respuesta del backend al procesar una imagen de recibo por OCR.
///
/// Mapea el JSON del endpoint `POST /api/v1/receipts/process`.
@JsonSerializable(explicitToJson: true)
class ReceiptProcessResponse {
  /// Nombre del proveedor detectado por OCR.
  final String detectedSupplier;

  /// Fecha de compra detectada por OCR (puede ser nula).
  final String? detectedDate;

  /// Líneas de productos detectadas por OCR.
  final List<ProductLineDto> lines;

  /// URL pública de la imagen subida al backend.
  final String imageUrl;

  /// Crea un [ReceiptProcessResponse] con todos los campos requeridos.
  const ReceiptProcessResponse({
    required this.detectedSupplier,
    this.detectedDate,
    required this.lines,
    required this.imageUrl,
  });

  /// Construye un [ReceiptProcessResponse] desde un mapa JSON.
  factory ReceiptProcessResponse.fromJson(Map<String, dynamic> json) =>
      _$ReceiptProcessResponseFromJson(json);

  /// Serializa a mapa JSON.
  Map<String, dynamic> toJson() => _$ReceiptProcessResponseToJson(this);
}

/// Extensión para convertir [ReceiptProcessResponse] a entidad de dominio [Receipt].
extension ReceiptProcessResponseMapper on ReceiptProcessResponse {
  /// Convierte este DTO en un [Receipt] del dominio.
  ///
  /// Nota: la entidad [Receipt] no tiene campos para [detectedSupplier],
  /// [lines] ni [imageUrl]. Se mapean solo los campos compatibles.
  Receipt toEntity() => Receipt(
    id: 0, // La respuesta OCR no tiene ID asignado
    filename: imageUrl,
    detectedDate: detectedDate != null
        ? DateTime.tryParse(detectedDate!)
        : null,
    status: 'pending',
    items: const [],
  );
}
