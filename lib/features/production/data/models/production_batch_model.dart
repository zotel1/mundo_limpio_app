import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/production_batch.dart';

part 'production_batch_model.g.dart';

@JsonSerializable()
class ProductionBatchModel {
  final int id;
  @JsonKey(name: 'finished_product_id')
  final int finishedProductId;
  @JsonKey(name: 'bulk_product_id')
  final int bulkProductId;
  @JsonKey(name: 'quantity_used')
  final double quantityUsed;
  @JsonKey(name: 'quantity_produced')
  final double quantityProduced;
  final DateTime date;

  const ProductionBatchModel({
    required this.id,
    required this.finishedProductId,
    required this.bulkProductId,
    required this.quantityUsed,
    required this.quantityProduced,
    required this.date,
  });

  factory ProductionBatchModel.fromJson(Map<String, dynamic> json) =>
      _$ProductionBatchModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductionBatchModelToJson(this);

  ProductionBatch toEntity() {
    return ProductionBatch(
      id: id,
      finishedProductId: finishedProductId,
      bulkProductId: bulkProductId,
      quantityUsed: quantityUsed,
      quantityProduced: quantityProduced,
      date: date,
    );
  }
}
