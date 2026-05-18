// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulkProductModel _$BulkProductModelFromJson(Map<String, dynamic> json) =>
    BulkProductModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      unitOfMeasure: json['unit_of_measure'] as String,
      stock: (json['stock'] as num).toDouble(),
    );

Map<String, dynamic> _$BulkProductModelToJson(BulkProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'unit_of_measure': instance.unitOfMeasure,
      'stock': instance.stock,
    };
