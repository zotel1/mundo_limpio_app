// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_line_confirm_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductLineConfirmDto _$ProductLineConfirmDtoFromJson(
  Map<String, dynamic> json,
) => ProductLineConfirmDto(
  description: json['description'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unitPrice'] as num).toDouble(),
  bulkProductId: (json['bulkProductId'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProductLineConfirmDtoToJson(
  ProductLineConfirmDto instance,
) => <String, dynamic>{
  'description': instance.description,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'bulkProductId': instance.bulkProductId,
};
