// Pruebas unitarias para la entidad BatchInfo.
//
// BatchInfo representa los datos de un lote de producción
// necesarios en el contrato del repositorio de ventas.
//
// TDD: RED — test escrito antes de crear la entidad

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/batch_info.dart';

void main() {
  group('BatchInfo', () {
    // TDD: RED
    test('should create instance with id, productId, and quantity', () {
      const batch = BatchInfo(id: 10, productId: 5, quantity: 24.5);

      expect(batch.id, 10);
      expect(batch.productId, 5);
      expect(batch.quantity, 24.5);
    });

    // TDD: RED
    test('should be equal when all fields are the same', () {
      const batch1 = BatchInfo(id: 10, productId: 5, quantity: 24.5);
      const batch2 = BatchInfo(id: 10, productId: 5, quantity: 24.5);

      expect(batch1, equals(batch2));
      expect(batch1.hashCode, equals(batch2.hashCode));
    });

    // TDD: RED
    test('should NOT be equal when id differs', () {
      const batch1 = BatchInfo(id: 10, productId: 5, quantity: 24.5);
      const batch2 = BatchInfo(id: 20, productId: 5, quantity: 24.5);

      expect(batch1, isNot(equals(batch2)));
    });

    // TDD: RED
    test('should NOT be equal when productId differs', () {
      const batch1 = BatchInfo(id: 10, productId: 5, quantity: 24.5);
      const batch2 = BatchInfo(id: 10, productId: 8, quantity: 24.5);

      expect(batch1, isNot(equals(batch2)));
    });

    // TDD: RED — triangulation: quantity is a double with decimal precision
    test('should NOT be equal when quantity differs', () {
      const batch1 = BatchInfo(id: 10, productId: 5, quantity: 24.5);
      const batch2 = BatchInfo(id: 10, productId: 5, quantity: 30.0);

      expect(batch1, isNot(equals(batch2)));
    });

    // TDD: RED — triangulation: negative quantity is valid (represents data)
    test('should support zero quantity', () {
      const batch = BatchInfo(id: 10, productId: 5, quantity: 0.0);

      expect(batch.quantity, 0.0);
    });
  });
}
