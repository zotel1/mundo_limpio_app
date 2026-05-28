import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/bulk_product.dart';

part 'bulk_product_model.g.dart';

@JsonSerializable()
class BulkProductModel {
  final int id;
  final String name;
  final double currentStockLiters;
  final double costPerLiter;
  final double conversionRatio;
  @JsonKey(defaultValue: true)
  final bool active;

  const BulkProductModel({
    required this.id,
    required this.name,
    required this.currentStockLiters,
    required this.costPerLiter,
    required this.conversionRatio,
    this.active = true,
  });

  factory BulkProductModel.fromJson(Map<String, dynamic> json) =>
      _$BulkProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$BulkProductModelToJson(this);

  BulkProduct toEntity() {
    return BulkProduct(
      id: id,
      name: name,
      currentStockLiters: currentStockLiters,
      costPerLiter: costPerLiter,
      conversionRatio: conversionRatio,
      active: active,
    );
  }
}
