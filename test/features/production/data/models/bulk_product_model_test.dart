// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/production/data/models/bulk_product_model.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';

void main() {
  group('BulkProductModel', () {
    final Map<String, dynamic> json = {
      'id': 1,
      'name': 'Alcohol Etílico',
      'currentStockLiters': 500.0,
      'costPerLiter': 12.5,
      'conversionRatio': 1.0,
      'active': true,
    };

    test(
      'debe crear una instancia de BulkProductModel desde JSON correctamente',
      () {
        final model = BulkProductModel.fromJson(json);

        expect(model.id, 1);
        expect(model.name, 'Alcohol Etílico');
        expect(model.currentStockLiters, 500.0);
        expect(model.costPerLiter, 12.5);
        expect(model.conversionRatio, 1.0);
        expect(model.active, true);
      },
    );

    test('debe convertir un BulkProductModel a JSON correctamente', () {
      final model = BulkProductModel(
        id: 1,
        name: 'Alcohol Etílico',
        currentStockLiters: 500.0,
        costPerLiter: 12.5,
        conversionRatio: 1.0,
        active: true,
      );
      final result = model.toJson();

      expect(result['id'], 1);
      expect(result['name'], 'Alcohol Etílico');
      expect(result['currentStockLiters'], 500.0);
      expect(result['costPerLiter'], 12.5);
      expect(result['conversionRatio'], 1.0);
      expect(result['active'], true);
    });

    test(
      'debe convertir un BulkProductModel a la entidad BulkProduct correctamente',
      () {
        final model = BulkProductModel(
          id: 1,
          name: 'Alcohol Etílico',
          currentStockLiters: 500.0,
          costPerLiter: 12.5,
          conversionRatio: 1.0,
          active: true,
        );
        final entity = model.toEntity();

        expect(entity, isA<BulkProduct>());
        expect(entity.id, 1);
        expect(entity.name, 'Alcohol Etílico');
        expect(entity.currentStockLiters, 500.0);
        expect(entity.costPerLiter, 12.5);
        expect(entity.conversionRatio, 1.0);
        expect(entity.active, true);
      },
    );

    test(
      'debe manejar conversionRatio ausente como null y active default true',
      () {
        final jsonMinimal = {
          'id': 2,
          'name': 'Alcohol',
          'currentStockLiters': 100.0,
          'costPerLiter': 10.0,
        };
        final model = BulkProductModel.fromJson(jsonMinimal);

        expect(model.conversionRatio, isNull);
        expect(model.active, true);
      },
    );
  });
}
