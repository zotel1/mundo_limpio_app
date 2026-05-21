// Interfaz abstracta para el repositorio de notificaciones push.
// Wrapea FirebaseMessaging.instance para permitir testing con mocktail.
//
// Capa domain — NO importa Flutter, Dio, ni Provider.

import 'package:firebase_messaging/firebase_messaging.dart';

/// Contrato para operaciones de notificaciones push.
///
/// Separa FirebaseMessaging (dependencia concreta) de la logica de
/// presentacion, permitiendo mocktail en tests unitarios.
///
/// Escenarios del spec:
/// - R1: subscribeToTopic para recibir notificaciones de nuevas versiones.
/// - R2: requestPermission para solicitar permiso en Android 13+.
/// - R3: onMessage y onMessageOpenedApp para manejar foreground/background.
/// - R4: getInitialMessage para mensajes que abrieron la app desde terminada.
abstract class PushNotificationsRepository {
  /// Se suscribe al topic FCM especificado.
  ///
  /// Retorna true si la suscripcion fue exitosa.
  Future<bool> subscribeToTopic(String topic);

  /// Solicita permiso de notificaciones al usuario (Android 13+).
  ///
  /// Retorna [NotificationSettings] con el estado de autorizacion
  /// y configuracion de canales (sonido, badge, etc.).
  Future<NotificationSettings> requestPermission();

  /// Stream de mensajes recibidos en foreground.
  Stream<RemoteMessage> get onMessage;

  /// Stream de mensajes que abren la app desde background.
  Stream<RemoteMessage> get onMessageOpenedApp;

  /// Mensaje que abrio la app desde estado terminado, o null.
  Future<RemoteMessage?> getInitialMessage();
}
