import 'package:equatable/equatable.dart';

class ProductionBatch extends Equatable {
  final int id;
  final int productId;
  final String? productName;
  final int? bulkProductId;
  final String? bulkProductName;
  final double initialQuantity;
  final double currentStock;
  final double unitCostAtProduction;
  final double rawQuantityUsed;
  final DateTime productionDate;

  const ProductionBatch({
    required this.id,
    required this.productId,
    this.productName,
    this.bulkProductId,
    this.bulkProductName,
    required this.initialQuantity,
    required this.currentStock,
    required this.unitCostAtProduction,
    required this.rawQuantityUsed,
    required this.productionDate,
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    bulkProductId,
    bulkProductName,
    initialQuantity,
    currentStock,
    unitCostAtProduction,
    rawQuantityUsed,
    productionDate,
  ];
}
