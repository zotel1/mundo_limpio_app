// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryResponse _$InventoryResponseFromJson(Map<String, dynamic> json) =>
    InventoryResponse(
      productId: (json['productId'] as num).toInt(),
      productName: json['productName'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      minStockThreshold: (json['minStockThreshold'] as num).toDouble(),
    );

Map<String, dynamic> _$InventoryResponseToJson(InventoryResponse instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'currentStock': instance.currentStock,
      'minStockThreshold': instance.minStockThreshold,
    };
