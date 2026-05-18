// Pruebas unitarias para ProductionBatchResponse con @JsonSerializable.
// Verifica que fromJson/toJson funcionan correctamente después
// de la conversión desde el formato manual.
//
// TDD: RED — test escrito antes de convertir el modelo a @JsonSerializable

import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';

void main() {
  final jsonValid = {'id': 1, 'productId': 42, 'currentStock': 150.5};

  group('ProductionBatchResponse', () {
    test(
      'fromJson debe crear ProductionBatchResponse con todos los campos',
      () {
        final result = ProductionBatchResponse.fromJson(jsonValid);

        expect(result.id, 1);
        expect(result.productId, 42);
        expect(result.currentStock, 150.5);
      },
    );

    test('toJson debe producir el mapa JSON correcto', () {
      const response = ProductionBatchResponse(
        id: 10,
        productId: 99,
        currentStock: 200.0,
      );

      final json = response.toJson();

      expect(json['id'], 10);
      expect(json['productId'], 99);
      expect(json['currentStock'], 200.0);
    });

    test('round-trip fromJson → toJson debe preservar los datos', () {
      final original = ProductionBatchResponse.fromJson(jsonValid);
      final json = original.toJson();
      final restored = ProductionBatchResponse.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.productId, original.productId);
      expect(restored.currentStock, original.currentStock);
    });

    // Triangulación: currentStock en cero
    test('debe aceptar currentStock en cero', () {
      final json = {'id': 1, 'productId': 42, 'currentStock': 0.0};

      final result = ProductionBatchResponse.fromJson(json);

      expect(result.currentStock, 0.0);
    });
  });
}
