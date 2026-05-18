// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';

void main() {
  group('ProductionBatch Entity', () {
    test('debe crear una instancia de ProductionBatch correctamente', () {
      final date = DateTime(2026, 5, 18);
      final productionBatch = ProductionBatch(
        id: 1,
        finishedProductId: 10,
        bulkProductId: 20,
        quantityUsed: 5.0,
        quantityProduced: 4.0,
        date: date,
      );

      expect(productionBatch.id, 1);
      expect(productionBatch.finishedProductId, 10);
      expect(productionBatch.bulkProductId, 20);
      expect(productionBatch.quantityUsed, 5.0);
      expect(productionBatch.quantityProduced, 4.0);
      expect(productionBatch.date, date);
    });

    test('debe considerar dos ProductionBatches con los mismos valores como iguales', () {
      final date = DateTime(2026, 5, 18);
      final productionBatch1 = ProductionBatch(
        id: 1,
        finishedProductId: 10,
        bulkProductId: 20,
        quantityUsed: 5.0,
        quantityProduced: 4.0,
        date: date,
      );
      final productionBatch2 = ProductionBatch(
        id: 1,
        finishedProductId: 10,
        bulkProductId: 20,
        quantityUsed: 5.0,
        quantityProduced: 4.0,
        date: date,
      );

      expect(productionBatch1, equals(productionBatch2));
    });

    test('debe considerar dos ProductionBatches con diferentes valores como distintos', () {
      final date = DateTime(2026, 5, 18);
      final productionBatch1 = ProductionBatch(
        id: 1,
        finishedProductId: 10,
        bulkProductId: 20,
        quantityUsed: 5.0,
        quantityProduced: 4.0,
        date: date,
      );
      final productionBatch2 = ProductionBatch(
        id: 2,
        finishedProductId: 10,
        bulkProductId: 20,
        quantityUsed: 5.0,
        quantityProduced: 4.0,
        date: date,
      );

      expect(productionBatch1, isNot(equals(productionBatch2)));
    });
  });
}
