// Pruebas unitarias para SaleItemResponse.
// Verifica que el modelo se serializa/deserializa correctamente
// desde/hacia JSON usando json_serializable.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';

void main() {
  // Datos de ejemplo representando un ítem de venta típico del backend
  final jsonValid = {
    'batchId': 42,
    'productId': 5,
    'productName': 'Lavandina 3L',
    'quantity': 2.5,
    'unitPrice': 150.00,
    'unitCost': 100.00,
  };

  group('SaleItemResponse', () {
    // Verifica que fromJson construye correctamente el objeto
    // con todos los campos mapeados desde el JSON
    test('fromJson debe crear SaleItemResponse con todos los campos', () {
      final result = SaleItemResponse.fromJson(jsonValid);

      expect(result.batchId, jsonValid['batchId']);
      expect(result.productId, jsonValid['productId']);
      expect(result.productName, jsonValid['productName']);
      expect(result.quantity, jsonValid['quantity']);
      expect(result.unitPrice, jsonValid['unitPrice']);
      expect(result.unitCost, jsonValid['unitCost']);
    });

    // Verifica que toJson produce el mapa JSON correcto
    test('toJson debe producir el mapa JSON correcto', () {
      const response = SaleItemResponse(
        batchId: 7,
        productId: 5,
        productName: 'Lavandina 3L',
        quantity: 1.0,
        unitPrice: 200.50,
        unitCost: 120.00,
      );

      final json = response.toJson();

      expect(json['batchId'], 7);
      expect(json['productId'], 5);
      expect(json['productName'], 'Lavandina 3L');
      expect(json['quantity'], 1.0);
      expect(json['unitPrice'], 200.50);
      expect(json['unitCost'], 120.00);
    });

    // Round-trip: fromJson → toJson debe producir los mismos datos.
    test('round-trip fromJson → toJson debe preservar los datos', () {
      final original = SaleItemResponse.fromJson(jsonValid);
      final json = original.toJson();
      final restored = SaleItemResponse.fromJson(json);

      expect(restored.batchId, original.batchId);
      expect(restored.productId, original.productId);
      expect(restored.productName, original.productName);
      expect(restored.quantity, original.quantity);
      expect(restored.unitPrice, original.unitPrice);
      expect(restored.unitCost, original.unitCost);
    });

    // Triangulación: valores con ceros
    test('debe aceptar quantity cero', () {
      const response = SaleItemResponse(
        batchId: 1,
        productId: 0,
        productName: '',
        quantity: 0,
        unitPrice: 100.0,
        unitCost: 50.0,
      );

      final json = response.toJson();

      expect(json['quantity'], 0);
    });

    // Triangulación: valores negativos no deberían romper
    test('debe aceptar valores negativos en price/cost', () {
      const response = SaleItemResponse(
        batchId: 1,
        productId: 5,
        productName: 'Test',
        quantity: 1.0,
        unitPrice: -10.0,
        unitCost: -5.0,
      );

      final json = response.toJson();
      final restored = SaleItemResponse.fromJson(json);

      expect(restored.unitPrice, -10.0);
      expect(restored.unitCost, -5.0);
    });

    // Edge case: batchId 0
    test('debe aceptar batchId 0', () {
      const response = SaleItemResponse(
        batchId: 0,
        productId: 5,
        productName: 'Test',
        quantity: 1.0,
        unitPrice: 100.0,
        unitCost: 50.0,
      );

      expect(response.batchId, 0);
      expect(response.productId, 5);
      expect(response.productName, 'Test');
    });

    // Triangulación: productName con string vacío
    test('debe aceptar productName vacío', () {
      const response = SaleItemResponse(
        batchId: 1,
        productId: 0,
        productName: '',
        quantity: 1.0,
        unitPrice: 100.0,
        unitCost: 50.0,
      );

      expect(response.productName, '');
    });
  });
}
