// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulkProductModel _$BulkProductModelFromJson(Map<String, dynamic> json) =>
    BulkProductModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      currentStockLiters: (json['currentStockLiters'] as num).toDouble(),
      costPerLiter: (json['costPerLiter'] as num).toDouble(),
      conversionRatio: (json['conversionRatio'] as num).toDouble(),
      active: json['active'] as bool? ?? true,
    );

Map<String, dynamic> _$BulkProductModelToJson(BulkProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'currentStockLiters': instance.currentStockLiters,
      'costPerLiter': instance.costPerLiter,
      'conversionRatio': instance.conversionRatio,
      'active': instance.active,
    };
