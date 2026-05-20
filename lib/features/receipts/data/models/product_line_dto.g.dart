// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_line_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductLineDto _$ProductLineDtoFromJson(Map<String, dynamic> json) =>
    ProductLineDto(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      bulkProductId: (json['bulkProductId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductLineDtoToJson(ProductLineDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'confidence': instance.confidence,
      'bulkProductId': instance.bulkProductId,
    };
