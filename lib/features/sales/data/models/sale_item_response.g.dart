// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItemResponse _$SaleItemResponseFromJson(Map<String, dynamic> json) =>
    SaleItemResponse(
      batchId: (json['batchId'] as num).toInt(),
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
    );

Map<String, dynamic> _$SaleItemResponseToJson(SaleItemResponse instance) =>
    <String, dynamic>{
      'batchId': instance.batchId,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'unitCost': instance.unitCost,
    };
