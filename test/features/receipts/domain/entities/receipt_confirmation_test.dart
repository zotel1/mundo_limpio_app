// Pruebas unitarias para la entidad ReceiptConfirmation.
//
// ReceiptConfirmation agrupa los datos de confirmación de un recibo:
// imageUrl, supplierName, purchaseDate, y líneas de productos.
// Depende de ProductLineConfirm como sub-entidad.
//
// TDD: RED — test escrito antes de crear las entidades

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/product_line_confirm.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/receipt_confirmation.dart';

void main() {
  group('ReceiptConfirmation', () {
    // TDD: RED
    test('should create instance with all required fields', () {
      const line = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 12,
        unitPrice: 150.0,
      );
      const confirmation = ReceiptConfirmation(
        imageUrl: 'https://example.com/receipt.jpg',
        supplierName: 'Cervecería SA',
        purchaseDate: '2026-06-11',
        lines: [line],
      );

      expect(confirmation.imageUrl, 'https://example.com/receipt.jpg');
      expect(confirmation.supplierName, 'Cervecería SA');
      expect(confirmation.purchaseDate, '2026-06-11');
      expect(confirmation.lines.length, 1);
      expect(confirmation.lines.first.description, 'Cerveza IPA');
    });

    // TDD: RED
    test('should be equal when all fields are the same', () {
      const line = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 12,
        unitPrice: 150.0,
      );
      const c1 = ReceiptConfirmation(
        imageUrl: 'https://example.com/receipt.jpg',
        supplierName: 'Cervecería SA',
        purchaseDate: '2026-06-11',
        lines: [line],
      );
      const c2 = ReceiptConfirmation(
        imageUrl: 'https://example.com/receipt.jpg',
        supplierName: 'Cervecería SA',
        purchaseDate: '2026-06-11',
        lines: [line],
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    // TDD: RED
    test('should NOT be equal when supplierName differs', () {
      const line = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 12,
        unitPrice: 150.0,
      );
      const c1 = ReceiptConfirmation(
        imageUrl: 'https://example.com/receipt.jpg',
        supplierName: 'Cervecería SA',
        purchaseDate: '2026-06-11',
        lines: [line],
      );
      const c2 = ReceiptConfirmation(
        imageUrl: 'https://example.com/receipt.jpg',
        supplierName: 'Otra Cervecería',
        purchaseDate: '2026-06-11',
        lines: [line],
      );

      expect(c1, isNot(equals(c2)));
    });

    // TDD: RED
    test('should NOT be equal when lines differ', () {
      const line1 = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 12,
        unitPrice: 150.0,
      );
      const line2 = ProductLineConfirm(
        description: 'Cerveza Stout',
        quantity: 6,
        unitPrice: 180.0,
      );
      const c1 = ReceiptConfirmation(
        imageUrl: 'https://example.com/receipt.jpg',
        supplierName: 'Cervecería SA',
        purchaseDate: '2026-06-11',
        lines: [line1],
      );
      const c2 = ReceiptConfirmation(
        imageUrl: 'https://example.com/receipt.jpg',
        supplierName: 'Cervecería SA',
        purchaseDate: '2026-06-11',
        lines: [line2],
      );

      expect(c1, isNot(equals(c2)));
    });

    // TDD: RED — triangulation: multiple lines
    test('should support multiple product lines', () {
      const lines = [
        ProductLineConfirm(
          description: 'Cerveza IPA',
          quantity: 12,
          unitPrice: 150.0,
        ),
        ProductLineConfirm(
          description: 'Cerveza Stout',
          quantity: 6,
          unitPrice: 180.0,
        ),
      ];
      const confirmation = ReceiptConfirmation(
        imageUrl: 'https://example.com/receipt.jpg',
        supplierName: 'Cervecería SA',
        purchaseDate: '2026-06-11',
        lines: lines,
      );

      expect(confirmation.lines.length, 2);
      expect(confirmation.lines[0].quantity, 12);
      expect(confirmation.lines[1].description, 'Cerveza Stout');
    });
  });

  group('ProductLineConfirm', () {
    // TDD: RED
    test(
      'should create instance with description, quantity, and unitPrice',
      () {
        const line = ProductLineConfirm(
          description: 'Cerveza IPA',
          quantity: 12,
          unitPrice: 150.0,
        );

        expect(line.description, 'Cerveza IPA');
        expect(line.quantity, 12);
        expect(line.unitPrice, 150.0);
      },
    );

    // TDD: RED
    test('should create instance with optional bulkProductId', () {
      const line = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 12,
        unitPrice: 150.0,
        bulkProductId: 42,
      );

      expect(line.bulkProductId, 42);
    });

    // TDD: RED
    test('should be equal when all fields are the same', () {
      const line1 = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 12,
        unitPrice: 150.0,
        bulkProductId: 42,
      );
      const line2 = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 12,
        unitPrice: 150.0,
        bulkProductId: 42,
      );

      expect(line1, equals(line2));
      expect(line1.hashCode, equals(line2.hashCode));
    });

    // TDD: RED
    test('should NOT be equal when quantity differs', () {
      const line1 = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 12,
        unitPrice: 150.0,
      );
      const line2 = ProductLineConfirm(
        description: 'Cerveza IPA',
        quantity: 6,
        unitPrice: 150.0,
      );

      expect(line1, isNot(equals(line2)));
    });
  });
}
