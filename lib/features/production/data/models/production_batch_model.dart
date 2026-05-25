import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/production_batch.dart';

part 'production_batch_model.g.dart';

@JsonSerializable()
class ProductionBatchModel {
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

  const ProductionBatchModel({
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

  factory ProductionBatchModel.fromJson(Map<String, dynamic> json) =>
      _$ProductionBatchModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductionBatchModelToJson(this);

  ProductionBatch toEntity() {
    return ProductionBatch(
      id: id,
      productId: productId,
      productName: productName,
      bulkProductId: bulkProductId,
      bulkProductName: bulkProductName,
      initialQuantity: initialQuantity,
      currentStock: currentStock,
      unitCostAtProduction: unitCostAtProduction,
      rawQuantityUsed: rawQuantityUsed,
      productionDate: productionDate,
    );
  }
}
