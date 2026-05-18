// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_batch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductionBatchModel _$ProductionBatchModelFromJson(
  Map<String, dynamic> json,
) => ProductionBatchModel(
  id: (json['id'] as num).toInt(),
  finishedProductId: (json['finished_product_id'] as num).toInt(),
  bulkProductId: (json['bulk_product_id'] as num).toInt(),
  quantityUsed: (json['quantity_used'] as num).toDouble(),
  quantityProduced: (json['quantity_produced'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
);

Map<String, dynamic> _$ProductionBatchModelToJson(
  ProductionBatchModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'finished_product_id': instance.finishedProductId,
  'bulk_product_id': instance.bulkProductId,
  'quantity_used': instance.quantityUsed,
  'quantity_produced': instance.quantityProduced,
  'date': instance.date.toIso8601String(),
};
