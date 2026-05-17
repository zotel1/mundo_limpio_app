// Pruebas unitarias para AppConfig
// Verifica que la configuración base se cargue con valores por defecto
// y que los timeouts tengan los valores esperados.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    // R1 (indirecto): La URL base debe tener un valor por defecto
    // que apunte al backend local.
    test('should provide default baseUrl pointing to localhost:8080', () {
      expect(AppConfig.baseUrl, 'http://localhost:8080/api/v1');
    });

    // El timeout de conexión debe ser 10 segundos para
    // permitir reintentos sin bloquear la UI.
    test('should have 10 seconds connect timeout', () {
      expect(AppConfig.connectTimeout, const Duration(seconds: 10));
    });

    // El timeout de recepción debe ser 10 segundos para
    // dar tiempo suficiente a respuestas del backend.
    test('should have 10 seconds receive timeout', () {
      expect(AppConfig.receiveTimeout, const Duration(seconds: 10));
    });
  });
}
