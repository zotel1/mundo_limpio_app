// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentRequest _$AdjustmentRequestFromJson(Map<String, dynamic> json) =>
    AdjustmentRequest(
      type: $enumDecode(_$AdjustmentTypeEnumMap, json['type']),
      quantity: (json['quantity'] as num).toDouble(),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$AdjustmentRequestToJson(AdjustmentRequest instance) =>
    <String, dynamic>{
      'type': _$AdjustmentTypeEnumMap[instance.type]!,
      'quantity': instance.quantity,
      'reason': instance.reason,
    };

const _$AdjustmentTypeEnumMap = {
  AdjustmentType.ADJUSTMENT: 'ADJUSTMENT',
  AdjustmentType.BREAKAGE: 'BREAKAGE',
  AdjustmentType.RETURN: 'RETURN',
  AdjustmentType.QUALITY_LOSS: 'QUALITY_LOSS',
};
