// Servicio de reporte de crashes a Firebase Crashlytics.
//
// Clase estática que envuelve FirebaseCrashlytics para capturar:
// - Errores fatales de Flutter (FlutterError.onError)
// - Errores del PlatformDispatcher (PlatformDispatcher.instance.onError)
// - Errores manuales vía recordError()
//
// Soporta opt-out para que el usuario pueda desactivar el reporte,
// y setUser() para adjuntar metadata (userId + role) a cada crash.
//
// TDD: GREEN — implementación mínima

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static FirebaseCrashlytics? __testInstance;
  static bool _optOut = false;

  /// Instancia de FirebaseCrashlytics a usar.
  ///
  /// En producción usa [FirebaseCrashlytics.instance].
  /// En tests se inyecta via [testInstance] setter.
  static FirebaseCrashlytics get _instance =>
      __testInstance ?? FirebaseCrashlytics.instance;

  /// Setter para inyectar un mock de FirebaseCrashlytics en tests.
  @visibleForTesting
  static set testInstance(FirebaseCrashlytics? value) => __testInstance = value;

  /// Activa o desactiva el reporte de crashes.
  ///
  /// Cuando [value] es true, [recordError] no envía nada a Firebase.
  /// Útil para cumplir con GDPR o preferencias de usuario.
  static void setOptOut(bool value) {
    _optOut = value;
  }

  /// Inicializa Firebase Crashlytics.
  ///
  /// 1. Inicializa Firebase si aún no está inicializado.
  /// 2. Configura FlutterError.onError para capturar errores fatales.
  /// 3. Configura PlatformDispatcher.instance.onError para errores del framework.
  ///
  /// Debe llamarse ANTES de runApp() en main.dart.
  static Future<void> initialize() async {
    // Inicializar Firebase si no está inicializado (puede fallar en tests)
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      // Firebase no disponible en entorno de test — continuar sin crash
    }

    // Capturar errores fatales de Flutter (build, layout, paint)
    FlutterError.onError = (FlutterErrorDetails details) {
      // Pasamos el error al handler anterior para no romper el comportamiento
      // por defecto de Flutter (que imprime en consola)
      FlutterError.presentError(details);
      _instance.recordFlutterFatalError(details);
    };

    // Capturar errores del PlatformDispatcher (gestos, timers, etc.)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _instance.recordError(error, stack, fatal: true);
      return true; // true = el error fue manejado
    };
  }

  /// Asocia metadata del usuario autenticado a los crashes.
  ///
  /// [userId] es el identificador del usuario (username del backend).
  /// [role] es el rol del usuario (ej: 'admin', 'operator').
  ///
  /// Debe llamarse después de un login exitoso y en logout (con valores vacíos).
  ///
  /// Si Firebase no está disponible (ej: entorno de test), el error
  /// se captura silenciosamente para no romper el flujo de la app.
  static void setUser(String userId, String role) {
    try {
      _instance.setUserIdentifier(userId);
      _instance.setCustomKey('role', role);
    } catch (_) {
      // Firebase no disponible (test environment o inicialización pendiente)
    }
  }

  /// Reporta un error no fatal a Firebase Crashlytics.
  ///
  /// Si [setOptOut] está activado, el error NO se envía.
  /// [error] puede ser cualquier objeto (String, Exception, Error).
  /// [stack] es opcional — si no se provee, Firebase captura el stack actual.
  ///
  /// Si Firebase no está disponible, el error se descarta silenciosamente.
  static void recordError(dynamic error, [StackTrace? stack]) {
    if (_optOut) return;
    try {
      _instance.recordError(error, stack ?? StackTrace.empty, fatal: false);
    } catch (_) {
      // Firebase no disponible — no hacer nada
    }
  }

  /// Restaura el estado para tests (limpia mock y opt-out).
  @visibleForTesting
  static void resetForTesting() {
    __testInstance = null;
    _optOut = false;
  }
}
