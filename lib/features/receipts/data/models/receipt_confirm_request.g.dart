// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_confirm_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptConfirmRequest _$ReceiptConfirmRequestFromJson(
  Map<String, dynamic> json,
) => ReceiptConfirmRequest(
  imageUrl: json['imageUrl'] as String,
  supplierName: json['supplierName'] as String,
  purchaseDate: json['purchaseDate'] as String,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => ProductLineConfirmDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReceiptConfirmRequestToJson(
  ReceiptConfirmRequest instance,
) => <String, dynamic>{
  'imageUrl': instance.imageUrl,
  'supplierName': instance.supplierName,
  'purchaseDate': instance.purchaseDate,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
};
