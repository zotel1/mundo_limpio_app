// Pruebas unitarias para InventoryResponse.
// Verifica que el modelo se deserializa correctamente desde JSON
// usando json_serializable, con los campos: productId, productName,
// currentStock, minStockThreshold.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';

void main() {
  // JSON válido típico representando un ítem de inventario del backend
  final jsonValid = {
    'productId': 1,
    'productName': 'Jabón Líquido',
    'currentStock': 50.0,
    'minStockThreshold': 10.0,
  };

  group('InventoryResponse', () {
    // Verifica que fromJson construye correctamente el objeto
    // con todos los campos mapeados desde el JSON
    test('fromJson debe crear InventoryResponse con todos los campos', () {
      final result = InventoryResponse.fromJson(jsonValid);

      expect(result.productId, 1);
      expect(result.productName, 'Jabón Líquido');
      expect(result.currentStock, 50.0);
      expect(result.minStockThreshold, 10.0);
    });

    // Verifica que toJson produce el mapa JSON correcto
    test('toJson debe producir el mapa JSON correcto', () {
      final response = InventoryResponse(
        productId: 5,
        productName: 'Detergente',
        currentStock: 100.0,
        minStockThreshold: 20.0,
      );

      final json = response.toJson();

      expect(json['productId'], 5);
      expect(json['productName'], 'Detergente');
      expect(json['currentStock'], 100.0);
      expect(json['minStockThreshold'], 20.0);
    });

    // Round-trip: fromJson → toJson debe producir los mismos datos.
    test('round-trip fromJson → toJson debe preservar los datos', () {
      final original = InventoryResponse.fromJson(jsonValid);
      final json = original.toJson();
      final restored = InventoryResponse.fromJson(json);

      expect(restored.productId, original.productId);
      expect(restored.productName, original.productName);
      expect(restored.currentStock, original.currentStock);
      expect(restored.minStockThreshold, original.minStockThreshold);
    });

    // Triangulación: currentStock con decimales
    test('debe aceptar currentStock con decimales', () {
      final json = Map<String, dynamic>.from(jsonValid);
      json['currentStock'] = 25.75;

      final result = InventoryResponse.fromJson(json);

      expect(result.currentStock, 25.75);
    });

    // Triangulación: minStockThreshold con valor cero
    test('debe aceptar minStockThreshold en cero', () {
      final json = Map<String, dynamic>.from(jsonValid);
      json['minStockThreshold'] = 0.0;

      final result = InventoryResponse.fromJson(json);

      expect(result.minStockThreshold, 0.0);
    });
  });
}
