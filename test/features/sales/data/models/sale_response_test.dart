// Pruebas unitarias para SaleResponse.
// Verifica que el modelo se serializa/deserializa correctamente
// desde/hacia JSON usando json_serializable.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';

void main() {
  // Datos de ejemplo representando una venta típica del backend
  final jsonValid = {
    'id': 1,
    'totalAmount': 375.00,
    'createdAt': '2026-05-10T10:30:00.000',
    'items': [
      {
        'batchId': 42,
        'productId': 1,
        'productName': 'Test Product',
        'quantity': 2.5,
        'unitPrice': 150.00,
        'unitCost': 100.00,
      },
    ],
  };

  group('SaleResponse', () {
    // Verifica que fromJson construye correctamente el objeto
    // con todos los campos mapeados desde el JSON
    test('fromJson debe crear SaleResponse con todos los campos', () {
      final result = SaleResponse.fromJson(jsonValid);

      expect(result.id, jsonValid['id']);
      expect(result.totalAmount, jsonValid['totalAmount']);
      expect(result.createdAt, DateTime(2026, 5, 10, 10, 30, 0));
      expect(result.items, hasLength(1));
      expect(result.items[0].batchId, 42);
      expect(result.items[0].quantity, 2.5);
    });

    // Verifica que toJson produce el mapa JSON correcto
    test('toJson debe producir el mapa JSON correcto', () {
      final response = SaleResponse(
        id: 5,
        totalAmount: 500.00,
        createdAt: DateTime(2026, 5, 9, 12, 0, 0),
        items: const [
          SaleItemResponse(
            batchId: 10,
            productId: 1,
            productName: 'Test Product',
            quantity: 2.0,
            unitPrice: 200.00,
            unitCost: 150.00,
          ),
        ],
      );

      final json = response.toJson();

      expect(json['id'], 5);
      expect(json['totalAmount'], 500.00);
      expect(json['createdAt'], '2026-05-09T12:00:00.000');
      expect(json['items'], isA<List<dynamic>>());
      expect((json['items'] as List).length, 1);
    });

    // Round-trip: fromJson → toJson debe producir los mismos datos.
    test('round-trip fromJson → toJson debe preservar los datos', () {
      final original = SaleResponse.fromJson(jsonValid);
      final json = original.toJson();
      final restored = SaleResponse.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.totalAmount, original.totalAmount);
      expect(restored.createdAt, original.createdAt);
      expect(restored.items.length, original.items.length);
      expect(restored.items[0].batchId, original.items[0].batchId);
    });

    // Triangulación: lista vacía de items
    test('debe aceptar items vacío', () {
      final json = Map<String, dynamic>.from(jsonValid);
      json['items'] = <Map<String, dynamic>>[];

      final result = SaleResponse.fromJson(json);

      expect(result.items, isEmpty);
    });

    // Triangulación: totalAmount con decimales
    test('debe aceptar totalAmount con decimales', () {
      final json = Map<String, dynamic>.from(jsonValid);
      json['totalAmount'] = 99.99;

      final result = SaleResponse.fromJson(json);

      expect(result.totalAmount, 99.99);
    });

    // Edge case: createdAt sin milisegundos
    test('fromJson debe parsear createdAt sin milisegundos', () {
      final json = Map<String, dynamic>.from(jsonValid);
      json['createdAt'] = '2026-01-15T08:00:00';

      final result = SaleResponse.fromJson(json);

      expect(result.createdAt, DateTime(2026, 1, 15, 8, 0, 0));
    });

    // Edge case: múltiples items
    test('debe manejar múltiples items', () {
      final json = Map<String, dynamic>.from(jsonValid);
      json['items'] = [
        {
          'batchId': 1,
          'productId': 1,
          'productName': 'Product A',
          'quantity': 1.0,
          'unitPrice': 100.0,
          'unitCost': 50.0,
        },
        {
          'batchId': 2,
          'productId': 2,
          'productName': 'Product B',
          'quantity': 3.0,
          'unitPrice': 200.0,
          'unitCost': 120.0,
        },
      ];

      final result = SaleResponse.fromJson(json);

      expect(result.items, hasLength(2));
      expect(result.items[0].batchId, 1);
      expect(result.items[1].batchId, 2);
    });
  });

  // TDD: RED — tests para SaleResponse.draft() escrito antes de la implementación
  group('SaleResponse.draft()', () {
    test('debe crear un SaleResponse con id=-1, totalAmount=0, items=[]', () {
      final draft = SaleResponse.draft();

      expect(draft.id, -1);
      expect(draft.totalAmount, 0.0);
      expect(draft.items, isEmpty);
    });

    // Triangulación: createdAt no es null
    test('debe tener createdAt no nulo', () {
      final draft = SaleResponse.draft();

      expect(draft.createdAt, isNotNull);
      expect(
        draft.createdAt.isBefore(
          DateTime.now().add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    // Edge case: el draft es igual a otro draft (ids iguales)
    test('dos drafts deben tener el mismo id=-1', () {
      final draft1 = SaleResponse.draft();
      final draft2 = SaleResponse.draft();

      expect(draft1.id, -1);
      expect(draft2.id, -1);
      expect(draft1.id, draft2.id);
    });
  });
}
