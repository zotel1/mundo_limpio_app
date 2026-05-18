import 'package:equatable/equatable.dart';

class BulkProduct extends Equatable {
  final int id;
  final String name;
  final String unitOfMeasure;
  final double stock;

  const BulkProduct({
    required this.id,
    required this.name,
    required this.unitOfMeasure,
    required this.stock,
  });

  @override
  List<Object?> get props => [id, name, unitOfMeasure, stock];
}
