// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/products/data/models/product_model.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';

void main() {
  group('ProductModel', () {
    final Map<String, dynamic> json = {
      'id': 1,
      'sku': 'PROD-001',
      'name': 'Jabón Líquido',
      'minPrice': 150.0,
      'active': true,
    };

    test(
      'debe crear una instancia de ProductModel desde JSON correctamente',
      () {
        final model = ProductModel.fromJson(json);

        expect(model.id, 1);
        expect(model.sku, 'PROD-001');
        expect(model.name, 'Jabón Líquido');
        expect(model.minPrice, 150.0);
        expect(model.active, true);
      },
    );

    test('debe convertir un ProductModel a JSON correctamente', () {
      final model = ProductModel(
        id: 1,
        sku: 'PROD-001',
        name: 'Jabón Líquido',
        minPrice: 150.0,
        active: true,
      );
      final result = model.toJson();

      expect(result['id'], 1);
      expect(result['sku'], 'PROD-001');
      expect(result['name'], 'Jabón Líquido');
      expect(result['minPrice'], 150.0);
      expect(result['active'], true);
    });

    test(
      'debe convertir un ProductModel a la entidad Product correctamente',
      () {
        final model = ProductModel(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón Líquido',
          minPrice: 150.0,
          active: true,
        );
        final entity = model.toEntity();

        expect(entity, isA<Product>());
        expect(entity.id, 1);
        expect(entity.sku, 'PROD-001');
        expect(entity.name, 'Jabón Líquido');
        expect(entity.minPrice, 150.0);
        expect(entity.active, true);
      },
    );

    test('debe manejar campos nulos correctamente (sku y minPrice null)', () {
      final jsonWithNulls = {
        'id': 2,
        'sku': null,
        'name': 'Producto sin SKU',
        'minPrice': null,
        'active': true,
      };
      final model = ProductModel.fromJson(jsonWithNulls);

      expect(model.id, 2);
      expect(model.sku, isNull);
      expect(model.minPrice, isNull);
      expect(model.name, 'Producto sin SKU');
      expect(model.active, true);
    });

    test('debe crear ProductModel con active=false correctamente', () {
      final jsonInactive = {
        'id': 3,
        'sku': 'PROD-003',
        'name': 'Producto Inactivo',
        'minPrice': null,
        'active': false,
      };
      final model = ProductModel.fromJson(jsonInactive);

      expect(model.active, false);
    });
  });
}
