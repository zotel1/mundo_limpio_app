// Pruebas unitarias para la entidad CreateSaleData.
//
// CreateSaleData agrupa los datos necesarios para crear
// una venta: productId y quantity.
//
// TDD: RED — test escrito antes de crear la entidad

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/create_sale_data.dart';

void main() {
  group('CreateSaleData', () {
    // TDD: RED
    test('should create instance with productId and quantity', () {
      const data = CreateSaleData(productId: 1, quantity: 10.0);

      expect(data.productId, 1);
      expect(data.quantity, 10.0);
    });

    // TDD: RED
    test('should be equal when productId and quantity are the same', () {
      const data1 = CreateSaleData(productId: 1, quantity: 10.0);
      const data2 = CreateSaleData(productId: 1, quantity: 10.0);

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });

    // TDD: RED
    test('should NOT be equal when productId differs', () {
      const data1 = CreateSaleData(productId: 1, quantity: 10.0);
      const data2 = CreateSaleData(productId: 2, quantity: 10.0);

      expect(data1, isNot(equals(data2)));
    });

    // TDD: RED
    test('should NOT be equal when quantity differs', () {
      const data1 = CreateSaleData(productId: 1, quantity: 10.0);
      const data2 = CreateSaleData(productId: 1, quantity: 5.5);

      expect(data1, isNot(equals(data2)));
    });

    // TDD: RED — triangulation: supports fractional quantities
    test('should support fractional quantities', () {
      const data = CreateSaleData(productId: 3, quantity: 1.75);

      expect(data.quantity, 1.75);
      expect(data.productId, 3);
    });
  });
}
