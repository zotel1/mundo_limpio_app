// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/production/data/models/production_batch_model.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';

void main() {
  group('ProductionBatchModel', () {
    final dateStr = '2026-05-18T10:00:00Z';
    final Map<String, dynamic> json = {
      'id': 1,
      'productId': 10,
      'productName': 'Jabón Líquido',
      'bulkProductId': 20,
      'bulkProductName': 'Alcohol Etílico',
      'initialQuantity': 100.0,
      'currentStock': 85.0,
      'unitCostAtProduction': 12.5,
      'rawQuantityUsed': 15.0,
      'productionDate': dateStr,
    };

    test(
      'debe crear una instancia de ProductionBatchModel desde JSON correctamente',
      () {
        final model = ProductionBatchModel.fromJson(json);

        expect(model.id, 1);
        expect(model.productId, 10);
        expect(model.productName, 'Jabón Líquido');
        expect(model.bulkProductId, 20);
        expect(model.bulkProductName, 'Alcohol Etílico');
        expect(model.initialQuantity, 100.0);
        expect(model.currentStock, 85.0);
        expect(model.unitCostAtProduction, 12.5);
        expect(model.rawQuantityUsed, 15.0);
        expect(model.productionDate.toIso8601String(), contains('2026-05-18'));
      },
    );

    test('debe convertir un ProductionBatchModel a JSON correctamente', () {
      final date = DateTime.parse(dateStr);
      final model = ProductionBatchModel(
        id: 1,
        productId: 10,
        productName: 'Jabón Líquido',
        bulkProductId: 20,
        bulkProductName: 'Alcohol Etílico',
        initialQuantity: 100.0,
        currentStock: 85.0,
        unitCostAtProduction: 12.5,
        rawQuantityUsed: 15.0,
        productionDate: date,
      );
      final result = model.toJson();

      expect(result['id'], 1);
      expect(result['productId'], 10);
      expect(result['productName'], 'Jabón Líquido');
      expect(result['bulkProductId'], 20);
      expect(result['bulkProductName'], 'Alcohol Etílico');
      expect(result['initialQuantity'], 100.0);
      expect(result['currentStock'], 85.0);
      expect(result['unitCostAtProduction'], 12.5);
      expect(result['rawQuantityUsed'], 15.0);
      expect(result['productionDate'], contains('2026-05-18T10:00:00'));
    });

    test(
      'debe convertir un ProductionBatchModel a la entidad ProductionBatch correctamente',
      () {
        final date = DateTime.parse(dateStr);
        final model = ProductionBatchModel(
          id: 1,
          productId: 10,
          productName: 'Jabón Líquido',
          bulkProductId: 20,
          bulkProductName: 'Alcohol Etílico',
          initialQuantity: 100.0,
          currentStock: 85.0,
          unitCostAtProduction: 12.5,
          rawQuantityUsed: 15.0,
          productionDate: date,
        );
        final entity = model.toEntity();

        expect(entity, isA<ProductionBatch>());
        expect(entity.id, 1);
        expect(entity.productId, 10);
        expect(entity.productName, 'Jabón Líquido');
        expect(entity.bulkProductId, 20);
        expect(entity.bulkProductName, 'Alcohol Etílico');
        expect(entity.initialQuantity, 100.0);
        expect(entity.currentStock, 85.0);
        expect(entity.unitCostAtProduction, 12.5);
        expect(entity.rawQuantityUsed, 15.0);
        expect(entity.productionDate, date);
      },
    );

    test('debe manejar campos opcionales ausentes como null', () {
      final jsonMinimal = {
        'id': 2,
        'productId': 11,
        'initialQuantity': 50.0,
        'currentStock': 40.0,
        'unitCostAtProduction': 10.0,
        'rawQuantityUsed': 10.0,
        'productionDate': '2026-05-18T10:00:00Z',
      };
      final model = ProductionBatchModel.fromJson(jsonMinimal);

      expect(model.productName, isNull);
      expect(model.bulkProductId, isNull);
      expect(model.bulkProductName, isNull);
    });
  });
}
