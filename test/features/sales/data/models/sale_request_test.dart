// Pruebas unitarias para SaleRequest.
// Verifica que el modelo se serializa correctamente a JSON
// para enviarlo en el body de POST /sales.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';

void main() {
  group('SaleRequest', () {
    // Verifica que toJson produce el mapa JSON con productId y quantity
    test('toJson debe contener productId y quantity', () {
      const request = SaleRequest(productId: 1, quantity: 2.5);

      final json = request.toJson();

      expect(json['productId'], 1);
      expect(json['quantity'], 2.5);
    });

    // Verifica que fromJson construye el objeto desde un mapa JSON
    test('fromJson debe crear SaleRequest con todos los campos', () {
      final json = {'productId': 10, 'quantity': 3.0};

      final result = SaleRequest.fromJson(json);

      expect(result.productId, 10);
      expect(result.quantity, 3.0);
    });

    // Round-trip: fromJson → toJson debe preservar los datos.
    // Garantiza que serialización y deserialización son inversas.
    test('round-trip fromJson → toJson debe preservar los datos', () {
      const original = SaleRequest(productId: 5, quantity: 1.75);

      final json = original.toJson();
      final restored = SaleRequest.fromJson(json);

      expect(restored.productId, original.productId);
      expect(restored.quantity, original.quantity);
    });

    // Triangulación: values con decimales
    test('debe aceptar quantity con decimales', () {
      const request = SaleRequest(productId: 7, quantity: 0.33);

      final json = request.toJson();

      expect(json['quantity'], 0.33);
    });

    // Triangulación: productId grande
    test('debe aceptar productId grande', () {
      const request = SaleRequest(productId: 99999, quantity: 100.0);

      final json = request.toJson();

      expect(json['productId'], 99999);
    });
  });
}
