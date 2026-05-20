// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseItemResponse _$PurchaseItemResponseFromJson(
  Map<String, dynamic> json,
) => PurchaseItemResponse(
  id: (json['id'] as num).toInt(),
  description: json['description'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unitPrice'] as num).toDouble(),
  totalPrice: (json['totalPrice'] as num).toDouble(),
  bulkProductId: (json['bulkProductId'] as num?)?.toInt(),
);

Map<String, dynamic> _$PurchaseItemResponseToJson(
  PurchaseItemResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'description': instance.description,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'totalPrice': instance.totalPrice,
  'bulkProductId': instance.bulkProductId,
};
