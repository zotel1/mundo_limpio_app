// TDD: GREEN — implementacion minima que pasa los tests.
//
// Implementacion concreta de PushNotificationsRepository.
// Wrapea FirebaseMessaging.instance para operaciones de instancia
// y expone los streams estaticos de FCM directamente.
//
// El constructor acepta un FirebaseMessaging opcional para testing:
// - En produccion: FirebaseMessaging.instance por defecto.
// - En tests: se inyecta un MockFirebaseMessaging via mocktail.
//
// Escenarios del spec:
// - R1: subscribeToTopic retorna true (exito) o false (excepcion).
// - R2: requestPermission delega a la instancia.
// - R3: onMessage y onMessageOpenedApp exponen los streams estaticos.
// - R4: getInitialMessage delega a la instancia.

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:mundo_limpio_app/features/notifications/domain/push_notifications_repository.dart';

/// Implementacion concreta que delega en [FirebaseMessaging].
///
/// Separa la dependencia de FirebaseMessaging del dominio,
/// permitiendo mocktail en tests unitarios.
class PushNotificationsRepositoryImpl implements PushNotificationsRepository {
  final FirebaseMessaging _messaging;

  /// Crea una instancia con un [FirebaseMessaging] opcional.
  ///
  /// En produccion usa [FirebaseMessaging.instance] por defecto.
  /// En tests se inyecta un mock de FirebaseMessaging.
  PushNotificationsRepositoryImpl({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  // ── R1: Suscripcion a topic FCM ────────────────────────────────────────

  @override
  Future<bool> subscribeToTopic(String topic) async {
    // FirebaseMessaging.subscribeToTopic no retorna valor en Android.
    // Si no lanza excepcion, se considera exito.
    try {
      await _messaging.subscribeToTopic(topic);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── R2: Solicitud de permiso ───────────────────────────────────────────

  @override
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission();
  }

  // ── R3: Streams de FCM (foreground y background) ───────────────────────
  //
  // Nota: onMessage y onMessageOpenedApp son getters ESTATICOS en la clase
  // FirebaseMessaging, no metodos de instancia. No se pueden mockear via
  // el constructor inyectado — se exponen directamente del static getter.
  // En tests verificamos por identidad con el static original.

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  // ── R4: Mensaje que abrio la app desde terminada ──────────────────────

  @override
  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }
}
