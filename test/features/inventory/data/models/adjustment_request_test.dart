// Pruebas unitarias para AdjustmentRequest.
// Verifica que el modelo se serializa correctamente a JSON
// con los campos: type (AdjustmentType enum), quantity (double),
// reason (String).
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';

void main() {
  group('AdjustmentRequest', () {
    // Verifica que toJson produce el mapa JSON correcto con tipo BREAKAGE
    test('toJson con BREAKAGE debe contener type, quantity y reason', () {
      const request = AdjustmentRequest(
        type: AdjustmentType.BREAKAGE,
        quantity: -5.0,
        reason: 'quebrado en transporte',
      );

      final json = request.toJson();

      expect(json['type'], 'BREAKAGE');
      expect(json['quantity'], -5.0);
      expect(json['reason'], 'quebrado en transporte');
    });

    // Triangulación: todos los tipos del enum
    test('toJson con ADJUSTMENT debe serializar type correctamente', () {
      const request = AdjustmentRequest(
        type: AdjustmentType.ADJUSTMENT,
        quantity: 10.0,
        reason: 'ajuste manual',
      );

      final json = request.toJson();

      expect(json['type'], 'ADJUSTMENT');
      expect(json['quantity'], 10.0);
    });

    test('toJson con RETURN debe serializar type correctamente', () {
      const request = AdjustmentRequest(
        type: AdjustmentType.RETURN,
        quantity: 3.0,
        reason: 'product devuelto',
      );

      final json = request.toJson();

      expect(json['type'], 'RETURN');
      expect(json['quantity'], 3.0);
    });

    test('toJson con QUALITY_LOSS debe serializar type correctamente', () {
      const request = AdjustmentRequest(
        type: AdjustmentType.QUALITY_LOSS,
        quantity: -2.0,
        reason: 'pérdida por calidad',
      );

      final json = request.toJson();

      expect(json['type'], 'QUALITY_LOSS');
      expect(json['quantity'], -2.0);
    });

    // Verifica que fromJson construye el objeto desde un mapa JSON
    test('fromJson debe crear AdjustmentRequest con todos los campos', () {
      final json = {
        'type': 'ADJUSTMENT',
        'quantity': 5.0,
        'reason': 'ajuste de stock',
      };

      final result = AdjustmentRequest.fromJson(json);

      expect(result.type, AdjustmentType.ADJUSTMENT);
      expect(result.quantity, 5.0);
      expect(result.reason, 'ajuste de stock');
    });

    // Round-trip: fromJson → toJson debe preservar los datos
    test('round-trip fromJson → toJson debe preservar los datos', () {
      const original = AdjustmentRequest(
        type: AdjustmentType.RETURN,
        quantity: 2.5,
        reason: 'devolución cliente',
      );

      final json = original.toJson();
      final restored = AdjustmentRequest.fromJson(json);

      expect(restored.type, original.type);
      expect(restored.quantity, original.quantity);
      expect(restored.reason, original.reason);
    });
  });
}
