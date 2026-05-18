// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/production/data/models/bulk_product_model.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';

void main() {
  group('BulkProductModel', () {
    final Map<String, dynamic> json = {
      'id': 1,
      'name': 'Alcohol Etílico',
      'unit_of_measure': 'Litros',
      'stock': 100.0,
    };

    test(
      'debe crear una instancia de BulkProductModel desde JSON correctamente',
      () {
        final model = BulkProductModel.fromJson(json);

        expect(model.id, 1);
        expect(model.name, 'Alcohol Etílico');
        expect(model.unitOfMeasure, 'Litros');
        expect(model.stock, 100.0);
      },
    );

    test('debe convertir un BulkProductModel a JSON correctamente', () {
      final model = BulkProductModel(
        id: 1,
        name: 'Alcohol Etílico',
        unitOfMeasure: 'Litros',
        stock: 100.0,
      );
      final result = model.toJson();

      expect(result['id'], 1);
      expect(result['name'], 'Alcohol Etílico');
      expect(result['unit_of_measure'], 'Litros');
      expect(result['stock'], 100.0);
    });

    test(
      'debe convertir un BulkProductModel a la entidad BulkProduct correctamente',
      () {
        final model = BulkProductModel(
          id: 1,
          name: 'Alcohol Etílico',
          unitOfMeasure: 'Litros',
          stock: 100.0,
        );
        final entity = model.toEntity();

        expect(entity, isA<BulkProduct>());
        expect(entity.id, 1);
        expect(entity.name, 'Alcohol Etílico');
        expect(entity.unitOfMeasure, 'Litros');
        expect(entity.stock, 100.0);
      },
    );
  });
}
