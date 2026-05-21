// TDD: RED — test escrito ANTES que la implementacion.
//
// Pruebas unitarias para UrlLauncherService.
// Patron identico a CrashlyticsService: testInstance setter para inyectar
// callbacks en tests, resetForTesting para restaurar estado.
//
// Escenarios del spec r4-deep-link-fix:
// - testInstance delega al callback inyectado cuando launchUrl es llamado.
// - launchUrl parsea el string URL y pasa el Uri correcto al callback.
// - resetForTesting limpia el mock, restaurando al launcher real.
//
// Capa de test: Unit — callback spy, sin dependencias externas.

import 'package:flutter_test/flutter_test.dart';

// La implementacion NO existe aun — este import fallara en analisis
// hasta que se cree el archivo en la fase GREEN.
// ignore_for_file: import_of_legacy_library_into_null_safe
import 'package:mundo_limpio_app/core/services/url_launcher_service.dart';

void main() {
  tearDown(() {
    UrlLauncherService.resetForTesting();
  });

  group('testInstance — delegacion del callback', () {
    test('debe llamar al callback inyectado via testInstance cuando se invoca '
        'launchUrl con una URL valida', () {
      // TDD: RED — Arrange
      Uri? capturedUri;
      UrlLauncherService.testInstance = (Uri uri) {
        capturedUri = uri;
      };

      // TDD: RED — Act
      UrlLauncherService.launchUrl('https://appdistribution.firebase.dev/i/923159339728');

      // TDD: RED — Assert
      expect(capturedUri, isNotNull);
      expect(capturedUri!.scheme, 'https');
      expect(capturedUri!.host, 'appdistribution.firebase.dev');
      expect(capturedUri!.path, '/i/923159339728');
    });

    test('debe parsear correctamente distintos formatos de URL', () {
      // TDD: RED — TRIANGULATE: URL con query params
      Uri? capturedUri;
      UrlLauncherService.testInstance = (Uri uri) {
        capturedUri = uri;
      };

      // TDD: RED — Act
      UrlLauncherService.launchUrl('market://details?id=com.mundolimpio.app');

      // TDD: RED — Assert
      expect(capturedUri, isNotNull);
      expect(capturedUri!.scheme, 'market');
      expect(capturedUri!.host, 'details');
      expect(capturedUri!.queryParameters['id'], 'com.mundolimpio.app');
    });
  });

  group('resetForTesting — restauracion de estado', () {
    test('debe limpiar el testInstance, permitiendo inyectar uno nuevo', () {
      // TDD: RED — Arrange: inyectar primer callback, luego resetear
      var firstCalled = false;
      UrlLauncherService.testInstance = (Uri uri) {
        firstCalled = true;
      };
      UrlLauncherService.resetForTesting();

      // TDD: RED — Arrange: inyectar segundo callback (debe funcionar)
      var secondCalled = false;
      Uri? secondUri;
      UrlLauncherService.testInstance = (Uri uri) {
        secondCalled = true;
        secondUri = uri;
      };

      // TDD: RED — Act: launchUrl con el nuevo testInstance
      UrlLauncherService.launchUrl('https://test-reset.example.com/reset');

      // TDD: RED — Assert: el primer callback NO fue llamado,
      // el segundo SI fue llamado con la URL correcta
      expect(firstCalled, isFalse);
      expect(secondCalled, isTrue);
      expect(secondUri, isNotNull);
      expect(secondUri!.host, 'test-reset.example.com');
    });
  });
}
