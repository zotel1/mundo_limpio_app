import 'package:equatable/equatable.dart';

class BulkProduct extends Equatable {
  final int id;
  final String name;
  final double currentStockLiters;
  final double costPerLiter;
  final double? conversionRatio;
  final bool active;

  const BulkProduct({
    required this.id,
    required this.name,
    required this.currentStockLiters,
    required this.costPerLiter,
    this.conversionRatio,
    this.active = true,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    currentStockLiters,
    costPerLiter,
    conversionRatio,
    active,
  ];
}
