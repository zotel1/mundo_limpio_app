// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_process_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptProcessResponse _$ReceiptProcessResponseFromJson(
  Map<String, dynamic> json,
) => ReceiptProcessResponse(
  detectedSupplier: json['detectedSupplier'] as String,
  detectedDate: json['detectedDate'] as String?,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => ProductLineDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  imageUrl: json['imageUrl'] as String,
);

Map<String, dynamic> _$ReceiptProcessResponseToJson(
  ReceiptProcessResponse instance,
) => <String, dynamic>{
  'detectedSupplier': instance.detectedSupplier,
  'detectedDate': instance.detectedDate,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'imageUrl': instance.imageUrl,
};
