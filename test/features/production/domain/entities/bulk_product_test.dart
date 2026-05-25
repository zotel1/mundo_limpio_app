// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';

void main() {
  group('BulkProduct Entity', () {
    test('debe crear una instancia de BulkProduct correctamente', () {
      final bulkProduct = BulkProduct(
        id: 1,
        name: 'Alcohol Etílico',
        currentStockLiters: 500.0,
        costPerLiter: 12.5,
        conversionRatio: 1.0,
        active: true,
      );

      expect(bulkProduct.id, 1);
      expect(bulkProduct.name, 'Alcohol Etílico');
      expect(bulkProduct.currentStockLiters, 500.0);
      expect(bulkProduct.costPerLiter, 12.5);
      expect(bulkProduct.conversionRatio, 1.0);
      expect(bulkProduct.active, true);
    });

    test(
      'debe considerar dos BulkProducts con los mismos valores como iguales',
      () {
        final bulkProduct1 = BulkProduct(
          id: 1,
          name: 'Alcohol Etílico',
          currentStockLiters: 500.0,
          costPerLiter: 12.5,
          conversionRatio: 1.0,
          active: true,
        );
        final bulkProduct2 = BulkProduct(
          id: 1,
          name: 'Alcohol Etílico',
          currentStockLiters: 500.0,
          costPerLiter: 12.5,
          conversionRatio: 1.0,
          active: true,
        );

        expect(bulkProduct1, equals(bulkProduct2));
      },
    );

    test(
      'debe considerar dos BulkProducts con diferentes valores como distintos',
      () {
        final bulkProduct1 = BulkProduct(
          id: 1,
          name: 'Alcohol Etílico',
          currentStockLiters: 500.0,
          costPerLiter: 12.5,
          conversionRatio: 1.0,
          active: true,
        );
        final bulkProduct2 = BulkProduct(
          id: 2,
          name: 'Alcohol Etílico',
          currentStockLiters: 500.0,
          costPerLiter: 12.5,
          conversionRatio: 1.0,
          active: true,
        );

        expect(bulkProduct1, isNot(equals(bulkProduct2)));
      },
    );

    test('debe tener active=true por defecto', () {
      final bulkProduct = BulkProduct(
        id: 1,
        name: 'Test',
        currentStockLiters: 100.0,
        costPerLiter: 10.0,
      );

      expect(bulkProduct.active, true);
    });
  });
}
