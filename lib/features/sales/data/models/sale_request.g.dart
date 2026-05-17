// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleRequest _$SaleRequestFromJson(Map<String, dynamic> json) => SaleRequest(
  productId: (json['productId'] as num).toInt(),
  quantity: (json['quantity'] as num).toDouble(),
);

Map<String, dynamic> _$SaleRequestToJson(SaleRequest instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
    };
