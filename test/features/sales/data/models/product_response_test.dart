// Pruebas unitarias para ProductResponse con @JsonSerializable.
// Verifica que fromJson/toJson funcionan correctamente después
// de la conversión desde el formato manual.
//
// TDD: RED — test escrito antes de convertir el modelo a @JsonSerializable

import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';

void main() {
  final jsonValid = {
    'id': 1,
    'name': 'Jabón Líquido',
  };

  group('ProductResponse', () {
    test('fromJson debe crear ProductResponse con todos los campos', () {
      final result = ProductResponse.fromJson(jsonValid);

      expect(result.id, 1);
      expect(result.name, 'Jabón Líquido');
    });

    test('toJson debe producir el mapa JSON correcto', () {
      const response = ProductResponse(id: 5, name: 'Cloro');

      final json = response.toJson();

      expect(json['id'], 5);
      expect(json['name'], 'Cloro');
    });

    test('round-trip fromJson → toJson debe preservar los datos', () {
      final original = ProductResponse.fromJson(jsonValid);
      final json = original.toJson();
      final restored = ProductResponse.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
    });

    // Triangulación: ID grande
    test('debe aceptar IDs grandes', () {
      final json = {'id': 99999, 'name': 'Producto XL'};

      final result = ProductResponse.fromJson(json);

      expect(result.id, 99999);
      expect(result.name, 'Producto XL');
    });
  });
}
