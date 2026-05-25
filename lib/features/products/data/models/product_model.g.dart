// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: (json['id'] as num).toInt(),
  sku: json['sku'] as String?,
  name: json['name'] as String,
  minPrice: (json['min_price'] as num?)?.toDouble(),
  active: json['active'] as bool? ?? true,
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sku': instance.sku,
      'name': instance.name,
      'min_price': instance.minPrice,
      'active': instance.active,
    };
