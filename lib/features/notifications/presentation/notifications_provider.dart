// TDD: GREEN — implementacion minima que pasa los tests.
//
// ChangeNotifier que reacciona a mensajes push en foreground.
// Escucha el stream onMessage del PushNotificationsRepository,
// actualiza lastMessage y notifica a los listeners del provider.
//
// Responsabilidades:
// - Almacenar el ultimo RemoteMessage recibido en foreground (lastMessage).
// - Notificar a los widgets via notifyListeners() cuando llega un mensaje.
// - Cancelar la suscripcion al stream en dispose().
// - Opcionalmente ejecutar un callback (para mostrar SnackBar, etc.).
//
// Escenarios del spec R3:
// - R3: Mensaje foreground actualiza lastMessage y notifica listeners.
// - R3: Callback onForegroundNotification para acciones de UI.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/features/notifications/domain/push_notifications_repository.dart';

/// Callback que se ejecuta cuando llega un mensaje en foreground.
///
/// Usado por la capa de UI para mostrar un SnackBar, dialog, etc.
typedef ForegroundNotificationCallback = void Function(RemoteMessage message);

/// Provider que expone el estado de notificaciones push en foreground.
///
/// Escucha [PushNotificationsRepository.onMessage] y actualiza
/// [lastMessage] con cada [RemoteMessage] recibido. Los widgets
/// pueden usar [addListener] o `Consumer<NotificationsProvider>`
/// para reaccionar a nuevas notificaciones.
///
/// El [onForegroundNotification] callback opcional permite a la UI
/// ejecutar acciones inmediatas como mostrar un SnackBar (R3).
class NotificationsProvider extends ChangeNotifier {
  final PushNotificationsRepository _repository;

  /// Suscripcion activa al stream onMessage del repositorio.
  /// Se cancela en [dispose].
  StreamSubscription<RemoteMessage>? _subscription;

  /// Callback opcional para notificaciones en foreground.
  final ForegroundNotificationCallback? _onForegroundNotification;

  /// Ultimo mensaje recibido en foreground, o null si no llego ninguno.
  RemoteMessage? _lastMessage;

  /// Crea un [NotificationsProvider] que escucha el stream
  /// [PushNotificationsRepository.onMessage].
  ///
  /// [onForegroundNotification] callback opcional invocado cuando
  /// llega un mensaje en foreground (ej: para mostrar un SnackBar).
  NotificationsProvider(
    this._repository, {
    ForegroundNotificationCallback? onForegroundNotification,
  }) : _onForegroundNotification = onForegroundNotification {
    _subscription = _repository.onMessage.listen(_onForegroundMessage);
  }

  // ── Estado expuesto ────────────────────────────────────────────────────

  /// El ultimo [RemoteMessage] recibido en foreground.
  RemoteMessage? get lastMessage => _lastMessage;

  /// Stream de mensajes en foreground expuesto por el repositorio.
  ///
  /// Permite al UI escuchar directamente el stream de FirebaseMessaging
  /// a traves del provider (sin acoplarse al repositorio directamente).
  Stream<RemoteMessage> get onMessage => _repository.onMessage;

  // ── Manejo de mensajes foreground ──────────────────────────────────────

  /// Procesa un mensaje recibido en foreground.
  ///
  /// Actualiza [lastMessage], notifica listeners y ejecuta el callback
  /// [onForegroundNotification] si fue provisto.
  void _onForegroundMessage(RemoteMessage message) {
    _lastMessage = message;
    notifyListeners();
    _onForegroundNotification?.call(message);
  }

  // ── Limpieza ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
