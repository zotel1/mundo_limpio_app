// TDD: GREEN — implementacion minima que pasa los tests.
//
// Servicio estatico wrapper de url_launcher para abrir URLs externas.
// Sigue el mismo patron que CrashlyticsService:
// - testInstance setter para inyectar callbacks en tests.
// - launchUrl(String) parsea la URL y delega al launcher inyectado o real.
//
// Usado por NotificationsService para abrir Firebase App Distribution
// cuando el usuario toca una notificacion push (R4 deep link).
//
// Escenarios del spec r4-deep-link-fix:
// - launchUrl parsea el string URL y lo pasa como Uri al launcher.
// - testInstance permite mockear el launcher en tests unitarios.
// - resetForTesting limpia el mock entre tests.

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class UrlLauncherService {
  /// Callback inyectado para tests (reemplaza al launcher real).
  static void Function(Uri)? __testInstance;

  /// Launcher activo: el mock de test si existe, sino el real.
  static void Function(Uri) get _launcher =>
      __testInstance ?? _realLaunch;

  /// Inyecta un callback de [void Function(Uri)] para tests.
  ///
  /// ```dart
  /// UrlLauncherService.testInstance = (Uri uri) { /* spy */ };
  /// ```
  /// Llamar [resetForTesting] en tearDown para restaurar el estado.
  @visibleForTesting
  static set testInstance(void Function(Uri)? fn) {
    __testInstance = fn;
  }

  /// Abre una URL en el browser externo del dispositivo.
  ///
  /// [urlString] debe ser una URL valida (ej: 'https://...').
  /// Si el parseo de la URL falla, lanza [FormatException].
  ///
  /// En tests, delega al callback inyectado via [testInstance].
  static void launchUrl(String urlString) {
    final uri = Uri.parse(urlString);
    _launcher(uri);
  }

  /// Implementacion real usando el paquete url_launcher.
  ///
  /// Abre la URL en el browser externo (Chrome, Safari, etc.)
  /// usando [LaunchMode.externalApplication].
  static void _realLaunch(Uri uri) {
    url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
  }

  /// Restaura el estado por defecto entre tests.
  @visibleForTesting
  static void resetForTesting() {
    __testInstance = null;
  }
}
