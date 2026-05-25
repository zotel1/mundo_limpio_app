// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';

void main() {
  group('Product Entity', () {
    test('debe crear una instancia de Product correctamente', () {
      const product = Product(
        id: 1,
        sku: 'PROD-001',
        name: 'Jabón Líquido',
        minPrice: 150.0,
        active: true,
      );

      expect(product.id, 1);
      expect(product.sku, 'PROD-001');
      expect(product.name, 'Jabón Líquido');
      expect(product.minPrice, 150.0);
      expect(product.active, true);
    });

    test(
      'debe considerar dos Products con los mismos valores como iguales',
      () {
        const product1 = Product(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón Líquido',
          minPrice: 150.0,
          active: true,
        );
        const product2 = Product(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón Líquido',
          minPrice: 150.0,
          active: true,
        );

        expect(product1, equals(product2));
      },
    );

    test(
      'debe considerar dos Products con diferentes valores como distintos',
      () {
        const product1 = Product(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón Líquido',
          minPrice: 150.0,
          active: true,
        );
        const product2 = Product(
          id: 2,
          sku: 'PROD-002',
          name: 'Detergente',
          minPrice: 200.0,
          active: false,
        );

        expect(product1, isNot(equals(product2)));
      },
    );

    test('debe crear un Product con valores por defecto para active', () {
      const product = Product(
        id: 3,
        sku: 'PROD-003',
        name: 'Desinfectante',
        minPrice: null,
        active: true,
      );

      expect(product.id, 3);
      expect(product.sku, 'PROD-003');
      expect(product.minPrice, isNull);
      expect(product.active, true);
    });

    test(
      'debe considerar dos Products con mismo id y diferente sku como distintos',
      () {
        const product1 = Product(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón Líquido',
          minPrice: null,
          active: true,
        );
        const product2 = Product(
          id: 1,
          sku: 'PROD-002',
          name: 'Jabón Líquido',
          minPrice: null,
          active: true,
        );

        expect(product1, isNot(equals(product2)));
      },
    );
  });
}
