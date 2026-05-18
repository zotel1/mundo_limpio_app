import 'package:equatable/equatable.dart';

class ProductionBatch extends Equatable {
  final int id;
  final int finishedProductId;
  final int bulkProductId;
  final double quantityUsed;
  final double quantityProduced;
  final DateTime date;

  const ProductionBatch({
    required this.id,
    required this.finishedProductId,
    required this.bulkProductId,
    required this.quantityUsed,
    required this.quantityProduced,
    required this.date,
  });

  @override
  List<Object?> get props => [
        id,
        finishedProductId,
        bulkProductId,
        quantityUsed,
        quantityProduced,
        date,
      ];
}
