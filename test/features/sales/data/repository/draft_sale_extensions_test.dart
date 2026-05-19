// Pruebas unitarias para la extensión DraftSale → SaleRequest.
//
// Verifica que el helper toRequest() convierte correctamente
// un DraftSale (registro de Drift) en un SaleRequest para
// ser enviado al backend al confirmar el borrador.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/repository/draft_sale_extensions.dart';

void main() {
  group('DraftSale.toRequest()', () {
    // RED: esta extensión aún no existe, la referencia causará
    // error de compilación hasta que se implemente.
    test('debe crear SaleRequest con productId y quantity del DraftSale', () {
      final draft = DraftSale(
        id: 1,
        productId: 42,
        productName: 'Producto Test',
        batchId: 10,
        quantity: 30.0,
        unitPrice: 150.0,
        status: 'draft',
        createdAt: DateTime(2026, 5, 10),
      );

      final request = draft.toRequest();

      expect(request, isA<SaleRequest>());
      expect(request.productId, 42);
      expect(request.quantity, 30.0);
    });

    // Triangulación: valores diferentes para verificar que no está hardcodeado
    test('debe usar los valores reales del draft (no hardcodeado)', () {
      final draft = DraftSale(
        id: 5,
        productId: 99,
        productName: 'Otro Producto',
        batchId: 7,
        quantity: 12.5,
        unitPrice: 200.0,
        status: 'draft',
        createdAt: DateTime(2026, 5, 11),
      );

      final request = draft.toRequest();

      expect(request.productId, 99);
      expect(request.quantity, 12.5);
    });

    // Edge case: cantidad decimal
    test('debe manejar cantidades con decimales', () {
      final draft = DraftSale(
        id: 1,
        productId: 1,
        productName: 'Test',
        batchId: 1,
        quantity: 0.75,
        unitPrice: 100.0,
        status: 'draft',
        createdAt: DateTime(2026),
      );

      final request = draft.toRequest();

      expect(request.quantity, 0.75);
    });
  });
}
