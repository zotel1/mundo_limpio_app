import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final int id;
  final String? sku;
  final String name;
  @JsonKey(name: 'min_price')
  final double? minPrice;
  final bool active;

  const ProductModel({
    required this.id,
    this.sku,
    required this.name,
    this.minPrice,
    this.active = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  Product toEntity() {
    return Product(
      id: id,
      sku: sku,
      name: name,
      minPrice: minPrice,
      active: active,
    );
  }
}
