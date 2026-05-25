// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';

void main() {
  group('ProductionBatch Entity', () {
    final date = DateTime(2026, 5, 18);

    test('debe crear una instancia de ProductionBatch correctamente', () {
      final productionBatch = ProductionBatch(
        id: 1,
        productId: 10,
        productName: 'Jabón Líquido',
        bulkProductId: 20,
        bulkProductName: 'Alcohol',
        initialQuantity: 100.0,
        currentStock: 85.0,
        unitCostAtProduction: 12.5,
        rawQuantityUsed: 15.0,
        productionDate: date,
      );

      expect(productionBatch.id, 1);
      expect(productionBatch.productId, 10);
      expect(productionBatch.productName, 'Jabón Líquido');
      expect(productionBatch.bulkProductId, 20);
      expect(productionBatch.bulkProductName, 'Alcohol');
      expect(productionBatch.initialQuantity, 100.0);
      expect(productionBatch.currentStock, 85.0);
      expect(productionBatch.unitCostAtProduction, 12.5);
      expect(productionBatch.rawQuantityUsed, 15.0);
      expect(productionBatch.productionDate, date);
    });

    test(
      'debe considerar dos ProductionBatches con los mismos valores como iguales',
      () {
        final productionBatch1 = ProductionBatch(
          id: 1,
          productId: 10,
          initialQuantity: 100.0,
          currentStock: 85.0,
          unitCostAtProduction: 12.5,
          rawQuantityUsed: 15.0,
          productionDate: date,
        );
        final productionBatch2 = ProductionBatch(
          id: 1,
          productId: 10,
          initialQuantity: 100.0,
          currentStock: 85.0,
          unitCostAtProduction: 12.5,
          rawQuantityUsed: 15.0,
          productionDate: date,
        );

        expect(productionBatch1, equals(productionBatch2));
      },
    );

    test(
      'debe considerar dos ProductionBatches con diferentes valores como distintos',
      () {
        final productionBatch1 = ProductionBatch(
          id: 1,
          productId: 10,
          initialQuantity: 100.0,
          currentStock: 85.0,
          unitCostAtProduction: 12.5,
          rawQuantityUsed: 15.0,
          productionDate: date,
        );
        final productionBatch2 = ProductionBatch(
          id: 2,
          productId: 10,
          initialQuantity: 100.0,
          currentStock: 85.0,
          unitCostAtProduction: 12.5,
          rawQuantityUsed: 15.0,
          productionDate: date,
        );

        expect(productionBatch1, isNot(equals(productionBatch2)));
      },
    );
  });
}
