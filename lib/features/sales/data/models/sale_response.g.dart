// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleResponse _$SaleResponseFromJson(Map<String, dynamic> json) => SaleResponse(
  id: (json['id'] as num).toInt(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItemResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SaleResponseToJson(SaleResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'totalAmount': instance.totalAmount,
      'createdAt': instance.createdAt.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
