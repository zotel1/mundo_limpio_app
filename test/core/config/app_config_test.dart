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
    // que apunte al backend en Render.
    test('should provide default baseUrl pointing to Render backend', () {
      expect(AppConfig.baseUrl, 'https://mundo-limpio-backend.onrender.com');
    });

    // TDD: RED — timeout actualizado para tolerar cold starts de Render (~30-60s).
    // El timeout de conexión debe ser 45 segundos para
    // tolerar cold starts del backend Render en free tier.
    test('should have 45 seconds connect timeout for Render cold starts', () {
      expect(AppConfig.connectTimeout, const Duration(seconds: 45));
    });

    // El timeout de recepción debe ser 10 segundos para
    // dar tiempo suficiente a respuestas del backend.
    test('should have 10 seconds receive timeout', () {
      expect(AppConfig.receiveTimeout, const Duration(seconds: 10));
    });
  });
}
