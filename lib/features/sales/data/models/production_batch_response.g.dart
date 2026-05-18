// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_batch_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductionBatchResponse _$ProductionBatchResponseFromJson(
  Map<String, dynamic> json,
) => ProductionBatchResponse(
  id: (json['id'] as num).toInt(),
  productId: (json['productId'] as num).toInt(),
  currentStock: (json['currentStock'] as num).toDouble(),
);

Map<String, dynamic> _$ProductionBatchResponseToJson(
  ProductionBatchResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'currentStock': instance.currentStock,
};
