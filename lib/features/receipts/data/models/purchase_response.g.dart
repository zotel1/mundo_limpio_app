// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseResponse _$PurchaseResponseFromJson(Map<String, dynamic> json) =>
    PurchaseResponse(
      id: (json['id'] as num).toInt(),
      imageUrl: json['imageUrl'] as String,
      supplierName: json['supplierName'] as String,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      total: (json['total'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((e) => PurchaseItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PurchaseResponseToJson(PurchaseResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'supplierName': instance.supplierName,
      'purchaseDate': instance.purchaseDate.toIso8601String(),
      'total': instance.total,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
