// TDD: GREEN — implementacion minima que pasa los tests.
//
// Servicio estatico de inicializacion de notificaciones push.
// Sigue el mismo patron que CrashlyticsService:
// - testInstance setter para inyectar mocks en tests.
// - initialize() llamado antes de runApp() en main.dart.
// - Errores se loguean via CrashlyticsService.recordError().
//
// Flujo de inicializacion:
// 1. Solicitar permiso de notificaciones.
// 2. Si es denegado → retornar (la app sigue funcionando, R6).
// 3. Si es concedido → suscribirse a 'app-updates' con retry (R1).
// 4. Retry con backoff exponencial: 1s, 2s, 4s (3 intentos max).
// 5. Si falla persistentemente → loguear a Crashlytics.
//
// Escenarios del spec R1-R6:
// - R1: Suscripcion a topic con retry y backoff exponencial.
// - R2: Solicitud de permiso antes de suscribirse.
// - R6: Errores de permiso/suscripcion no bloquean la app.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/crashlytics/crashlytics_service.dart';
import 'package:mundo_limpio_app/core/services/url_launcher_service.dart';
import 'package:mundo_limpio_app/features/notifications/data/push_notifications_repository_impl.dart';
import 'package:mundo_limpio_app/features/notifications/domain/push_notifications_repository.dart';

/// Servicio estatico para inicializar notificaciones push FCM.
///
/// Debe llamarse ANTES de runApp(), despues de CrashlyticsService.initialize().
///
/// Ejemplo en main.dart:
/// ```dart
/// await CrashlyticsService.initialize();
/// await NotificationsService.initialize();
/// runApp(MyApp());
/// ```
///
/// Para tests, inyectar un mock via [testInstance]:
/// ```dart
/// NotificationsService.testInstance = mockRepo;
/// ```
class NotificationsService {
  //  Instancia de repositorio

  /// Mock inyectado para tests (reemplaza al repositorio real).
  static PushNotificationsRepository? __testInstance;

  /// Repositorio por defecto para produccion.
  /// Usa [PushNotificationsRepositoryImpl] que wrapea FirebaseMessaging.instance.
  static final PushNotificationsRepository _defaultRepository =
      PushNotificationsRepositoryImpl();

  /// Repositorio activo: el mock de test si existe, sino el real.
  static PushNotificationsRepository get _repository =>
      __testInstance ?? _defaultRepository;

  /// Stream subscription para mensajes que abren la app desde background (R4).
  static StreamSubscription<RemoteMessage>? __onMessageOpenedAppSubscription;

  /// Inyecta un mock de [PushNotificationsRepository] para tests.
  ///
  /// ```dart
  /// NotificationsService.testInstance = mockRepo;
  /// ```
  /// Llamar [resetForTesting] en tearDown para restaurar el estado.
  @visibleForTesting
  static set testInstance(PushNotificationsRepository? repo) {
    __testInstance = repo;
  }

  //  Delays de retry (configurables para tests)

  /// Delays entre reintentos de suscripcion.
  ///
  /// En produccion: 1s, 2s, 4s (backoff exponencial).
  /// En tests se reducen a milisegundos para ejecucion rapida.
  @visibleForTesting
  static List<Duration> testRetryDelays = const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  //  Inicializacion

  /// Inicializa el servicio de notificaciones push.
  ///
  /// 1. Solicita permiso de notificaciones via [PushNotificationsRepository].
  /// 2. Si es denegado o falla → retorna sin error (R6).
  /// 3. Si es concedido → suscribe al topic 'app-updates' con retry.
  /// 4. Si la suscripcion falla 3 veces → loguea a Crashlytics.
  ///
  /// [repository] parametro opcional para override directo (tests).
  static Future<void> initialize({
    PushNotificationsRepository? repository,
  }) async {
    final repo = repository ?? _repository;

    // 1. Solicitar permiso
    final AuthorizationStatus authStatus;
    try {
      final settings = await repo.requestPermission();
      authStatus = settings.authorizationStatus;
    } catch (e, stack) {
      // Error inesperado al pedir permiso — loggear y continuar (R6)
      CrashlyticsService.recordError(e, stack);
      return;
    }

    // 2. Permiso denegado → retornar sin error (caso esperado)
    if (authStatus == AuthorizationStatus.denied) {
      return;
    }

    // 3. Suscribirse al topic con retry (R1)
    const topic = 'app-updates';
    var subscribed = false;

    for (var attempt = 0; attempt < testRetryDelays.length; attempt++) {
      final success = await repo.subscribeToTopic(topic);
      if (success) {
        subscribed = true;
        break;
      }

      // Si no es el ultimo intento, esperar el delay antes del siguiente
      if (attempt < testRetryDelays.length - 1) {
        await Future<void>.delayed(testRetryDelays[attempt]);
      }
    }

    // 4. Fallo persistente despues de todos los intentos
    if (!subscribed) {
      CrashlyticsService.recordError(
        'Failed to subscribe to topic $topic '
        'after ${testRetryDelays.length} attempts',
        StackTrace.current,
      );
    }

    // TDD: GREEN — R4: Deep link — mensaje que abrio la app desde terminada
    try {
      final initialMessage = await repo.getInitialMessage();
      final initialUrl = initialMessage?.data['url'];
      if (initialUrl != null && initialUrl.toString().trim().isNotEmpty) {
        try {
          UrlLauncherService.launchUrl(initialUrl.toString().trim());
        } catch (e, stack) {
          CrashlyticsService.recordError(e, stack);
        }
      }
    } catch (e, stack) {
      CrashlyticsService.recordError(e, stack);
    }

    // TDD: GREEN — R4: Deep link — stream para mensajes que abren la app
    // desde background
    __onMessageOpenedAppSubscription = _repository.onMessageOpenedApp.listen((
      message,
    ) {
      final url = message.data['url'];
      if (url != null && url.toString().trim().isNotEmpty) {
        try {
          UrlLauncherService.launchUrl(url.toString().trim());
        } catch (e, stack) {
          CrashlyticsService.recordError(e, stack);
        }
      }
    });
  }

  //  Reset para tests

  /// Verifica si hay una actualización disponible via Remote Config.
  ///
  /// Lee el valor `update_url` de Firebase Remote Config. Si no está vacío,
  /// abre la URL en el navegador o Play Store para que el usuario descargue
  /// la nueva versión.
  ///
  /// Debe llamarse después de [initialize] para asegurar que Firebase esté listo.
  ///
  /// Si Remote Config no está disponible (ej: emulador sin configuración),
  /// el error se captura silenciosamente para no romper el flujo.
  static Future<void> checkForUpdate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      final updateUrl = remoteConfig.getString('update_url');

      if (updateUrl.isNotEmpty) {
        UrlLauncherService.launchUrl(updateUrl);
      }
    } catch (_) {
      // No bloqueante — la app sigue funcionando sin actualización
    }
  }

  /// Restaura el estado por defecto entre tests.
  @visibleForTesting
  static void resetForTesting() {
    __testInstance = null;
    __onMessageOpenedAppSubscription?.cancel();
    __onMessageOpenedAppSubscription = null;
    testRetryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];
  }
}
