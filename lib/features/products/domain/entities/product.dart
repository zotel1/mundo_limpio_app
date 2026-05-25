import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String? sku;
  final String name;
  final double? minPrice;
  final bool active;

  const Product({
    required this.id,
    this.sku,
    required this.name,
    this.minPrice,
    this.active = true,
  });

  @override
  List<Object?> get props => [id, sku, name, minPrice, active];
}
