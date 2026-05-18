// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/production/data/models/production_batch_model.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';

void main() {
  group('ProductionBatchModel', () {
    final dateStr = '2026-05-18T10:00:00Z';
    final Map<String, dynamic> json = {
      'id': 1,
      'finished_product_id': 10,
      'bulk_product_id': 20,
      'quantity_used': 5.0,
      'quantity_produced': 4.0,
      'date': dateStr,
    };

    test(
      'debe crear una instancia de ProductionBatchModel desde JSON correctamente',
      () {
        final model = ProductionBatchModel.fromJson(json);

        expect(model.id, 1);
        expect(model.finishedProductId, 10);
        expect(model.bulkProductId, 20);
        expect(model.quantityUsed, 5.0);
        expect(model.quantityProduced, 4.0);
        expect(model.date.toIso8601String(), contains('2026-05-18'));
      },
    );

    test('debe convertir un ProductionBatchModel a JSON correctamente', () {
      final date = DateTime.parse(dateStr);
      final model = ProductionBatchModel(
        id: 1,
        finishedProductId: 10,
        bulkProductId: 20,
        quantityUsed: 5.0,
        quantityProduced: 4.0,
        date: date,
      );
      final result = model.toJson();

      expect(result['id'], 1);
      expect(result['finished_product_id'], 10);
      expect(result['bulk_product_id'], 20);
      expect(result['quantity_used'], 5.0);
      expect(result['quantity_produced'], 4.0);
      expect(result['date'], contains('2026-05-18T10:00:00'));
    });

    test(
      'debe convertir un ProductionBatchModel a la entidad ProductionBatch correctamente',
      () {
        final date = DateTime.parse(dateStr);
        final model = ProductionBatchModel(
          id: 1,
          finishedProductId: 10,
          bulkProductId: 20,
          quantityUsed: 5.0,
          quantityProduced: 4.0,
          date: date,
        );
        final entity = model.toEntity();

        expect(entity, isA<ProductionBatch>());
        expect(entity.id, 1);
        expect(entity.finishedProductId, 10);
        expect(entity.bulkProductId, 20);
        expect(entity.quantityUsed, 5.0);
        expect(entity.quantityProduced, 4.0);
        expect(entity.date, date);
      },
    );
  });
}
