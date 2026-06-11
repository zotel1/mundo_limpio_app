// Pruebas unitarias para la entidad ProductInfo.
//
// ProductInfo representa los datos mínimos de un producto
// necesarios en el contrato del repositorio de ventas.
//
// TDD: RED — test escrito antes de crear la entidad

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/product_info.dart';

void main() {
  group('ProductInfo', () {
    // TDD: RED
    test('should create instance with id and name', () {
      const product = ProductInfo(id: 1, name: 'Cerveza IPA');

      expect(product.id, 1);
      expect(product.name, 'Cerveza IPA');
    });

    // TDD: RED
    test('should be equal when id and name are the same', () {
      const product1 = ProductInfo(id: 1, name: 'Cerveza IPA');
      const product2 = ProductInfo(id: 1, name: 'Cerveza IPA');

      expect(product1, equals(product2));
      expect(product1.hashCode, equals(product2.hashCode));
    });

    // TDD: RED
    test('should NOT be equal when id differs', () {
      const product1 = ProductInfo(id: 1, name: 'Cerveza IPA');
      const product2 = ProductInfo(id: 2, name: 'Cerveza IPA');

      expect(product1, isNot(equals(product2)));
    });

    // TDD: RED
    test('should NOT be equal when name differs', () {
      const product1 = ProductInfo(id: 1, name: 'Cerveza IPA');
      const product2 = ProductInfo(id: 1, name: 'Cerveza Stout');

      expect(product1, isNot(equals(product2)));
    });

    // TDD: RED — triangulation: multiple constructors
    test('should support multiple distinct products', () {
      const product1 = ProductInfo(id: 1, name: 'Cerveza IPA');
      const product2 = ProductInfo(id: 2, name: 'Cerveza Stout');

      expect(product1.id, 1);
      expect(product2.id, 2);
      expect(product1, isNot(equals(product2)));
    });
  });
}
