import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/bulk_product.dart';

part 'bulk_product_model.g.dart';

@JsonSerializable()
class BulkProductModel {
  final int id;
  final String name;
  @JsonKey(name: 'unit_of_measure')
  final String unitOfMeasure;
  final double stock;

  const BulkProductModel({
    required this.id,
    required this.name,
    required this.unitOfMeasure,
    required this.stock,
  });

  factory BulkProductModel.fromJson(Map<String, dynamic> json) =>
      _$BulkProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$BulkProductModelToJson(this);

  BulkProduct toEntity() {
    return BulkProduct(
      id: id,
      name: name,
      unitOfMeasure: unitOfMeasure,
      stock: stock,
    );
  }
}
