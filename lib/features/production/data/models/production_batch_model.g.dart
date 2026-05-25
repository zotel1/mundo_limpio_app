// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_batch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductionBatchModel _$ProductionBatchModelFromJson(
  Map<String, dynamic> json,
) => ProductionBatchModel(
  id: (json['id'] as num).toInt(),
  productId: (json['productId'] as num).toInt(),
  productName: json['productName'] as String?,
  bulkProductId: (json['bulkProductId'] as num?)?.toInt(),
  bulkProductName: json['bulkProductName'] as String?,
  initialQuantity: (json['initialQuantity'] as num).toDouble(),
  currentStock: (json['currentStock'] as num).toDouble(),
  unitCostAtProduction: (json['unitCostAtProduction'] as num).toDouble(),
  rawQuantityUsed: (json['rawQuantityUsed'] as num).toDouble(),
  productionDate: DateTime.parse(json['productionDate'] as String),
);

Map<String, dynamic> _$ProductionBatchModelToJson(
  ProductionBatchModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'productName': instance.productName,
  'bulkProductId': instance.bulkProductId,
  'bulkProductName': instance.bulkProductName,
  'initialQuantity': instance.initialQuantity,
  'currentStock': instance.currentStock,
  'unitCostAtProduction': instance.unitCostAtProduction,
  'rawQuantityUsed': instance.rawQuantityUsed,
  'productionDate': instance.productionDate.toIso8601String(),
};
