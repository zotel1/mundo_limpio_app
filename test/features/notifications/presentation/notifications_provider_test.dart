// TDD: RED — test escrito ANTES que la implementacion.
//
// Pruebas unitarias para NotificationsProvider.
// Verifica que el ChangeNotifier:
// - Inicia con lastMessage nulo.
// - Actualiza lastMessage cuando onMessage emite en foreground.
// - Notifica a sus listeners via notifyListeners().
// - Maneja multiples mensajes secuenciales.
// - Cancela la suscripcion del stream al hacer dispose.
//
// Escenarios del spec R3:
// - R3: Mensaje recibido en foreground actualiza el estado del provider.
// - R3: El provider expone el stream onMessage para que el UI escuche.
//
// Capa de test: Unit — mocktail mock de PushNotificationsRepository.
// StreamController para controlar la emision de mensajes.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/notifications/domain/push_notifications_repository.dart';

// La implementacion NO existe aun — este import fallara en analisis
// hasta que se cree el archivo en la fase GREEN.
// ignore: unused_import
import 'package:mundo_limpio_app/features/notifications/presentation/notifications_provider.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

// Mismo patron que en notifications_service_test.dart.
class MockPushNotificationsRepository extends Mock
    implements PushNotificationsRepository {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late MockPushNotificationsRepository mockRepo;
  late StreamController<RemoteMessage> messageController;

  setUp(() {
    mockRepo = MockPushNotificationsRepository();
    messageController = StreamController<RemoteMessage>.broadcast();

    // El repositorio expone su stream onMessage desde el controller.
    when(() => mockRepo.onMessage).thenAnswer((_) => messageController.stream);
  });

  tearDown(() {
    messageController.close();
  });

  // ── Helper ──────────────────────────────────────────────────────────────

  /// Crea un [NotificationsProvider] y registra un listener que cuenta
  /// invocaciones de notifyListeners.
  (NotificationsProvider, List<int> notifications)
      createProviderWithListener() {
    final provider = NotificationsProvider(mockRepo);
    final calls = <int>[];
    provider.addListener(() => calls.add(calls.length));
    return (provider, calls);
  }

  // ── Estado inicial ──────────────────────────────────────────────────────

  group('NotificationsProvider — estado inicial', () {
    test('debe iniciar con lastMessage nulo', () {
      // Act
      final provider = NotificationsProvider(mockRepo);

      // Assert
      expect(provider.lastMessage, isNull);
    });

    test('debe exponer el stream onMessage del repositorio', () {
      // Arrange
      final provider = NotificationsProvider(mockRepo);

      // Act
      final stream = provider.onMessage;

      // Assert — el stream expuesto es el mismo que el del repositorio
      expect(stream, isNotNull);
    });
  });

  // ── Mensaje foreground ──────────────────────────────────────────────────

  group('NotificationsProvider — mensaje foreground (R3)', () {
    test(
      'debe actualizar lastMessage cuando onMessage emite un mensaje',
      () async {
        // Arrange
        final mockMessage = MockRemoteMessage();
        final (provider, listenerCalls) =     createProviderWithListener();

        // Act
        messageController.add(mockMessage);
        // Esperar que el microtask del stream se procese
        await Future<void>.delayed(Duration.zero);

        // Assert
        expect(provider.lastMessage, same(mockMessage));
        expect(
          listenerCalls.length,
          greaterThan(0),
          reason: 'notifyListeners debe haber sido llamado',
        );
      },
    );

    test('debe notificar a los listeners cuando llega un mensaje', () async {
      // Arrange
      final mockMessage = MockRemoteMessage();
      final (provider, listenerCalls) =     createProviderWithListener();

      // Act
      messageController.add(mockMessage);
      await Future<void>.delayed(Duration.zero);

      // Assert — el listener fue notificado al menos una vez
      expect(listenerCalls.length, equals(1));
      expect(provider.lastMessage, same(mockMessage));
    });
  });

  // ── Multiples mensajes ──────────────────────────────────────────────────

  group('NotificationsProvider — multiples mensajes', () {
    test('debe actualizar lastMessage con cada mensaje recibido', () async {
      // Arrange
      final (provider, listenerCalls) =     createProviderWithListener();
      final msg1 = MockRemoteMessage();
      final msg2 = MockRemoteMessage();
      final msg3 = MockRemoteMessage();

      // Act — mensaje 1
      messageController.add(msg1);
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(provider.lastMessage, same(msg1));
      expect(listenerCalls.length, equals(1));

      // Act — mensaje 2
      messageController.add(msg2);
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(provider.lastMessage, same(msg2));
      expect(listenerCalls.length, equals(2));

      // Act — mensaje 3 (triangulate)
      messageController.add(msg3);
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(provider.lastMessage, same(msg3));
      expect(listenerCalls.length, equals(3));
    });

    test('cada mensaje debe disparar exactamente una notificacion', () async {
      // Arrange
      final (provider, _) =     createProviderWithListener();
      final listenerCalls = <int>[];
      provider.addListener(() => listenerCalls.add(listenerCalls.length));

      // Act
      messageController.add(MockRemoteMessage());
      await Future<void>.delayed(Duration.zero);
      messageController.add(MockRemoteMessage());
      await Future<void>.delayed(Duration.zero);

      // Assert — exactamente 2 notificaciones para 2 mensajes
      expect(listenerCalls.length, equals(2));
    });
  });

  // ── Dispose ─────────────────────────────────────────────────────────────

  group('NotificationsProvider — dispose', () {
    test('debe cancelar la suscripcion del stream al hacer dispose', () async {
      // Arrange
      final (provider, listenerCalls) =     createProviderWithListener();

      // Act — dispose (cancela el stream subscription)
      provider.dispose();

      // Emitir un mensaje DESPUES del dispose
      messageController.add(MockRemoteMessage());
      await Future<void>.delayed(Duration.zero);

      // Assert — el listener NO fue notificado porque la suscripcion fue cancelada
      expect(listenerCalls.length, equals(0));
      // lastMessage no deberia haberse actualizado tampoco
      expect(provider.lastMessage, isNull);
    });

    test('el stream onMessage sigue siendo accesible despues de dispose', () {
      // Arrange
      final provider = NotificationsProvider(mockRepo);

      // Act
      provider.dispose();

      // Assert — el getter del stream del repositorio sigue vivo
      // (no es responsabilidad del provider cerrar el stream del repo,
      // solo cancelar SU suscripcion)
      expect(provider.onMessage, isNotNull);
    });
  });

  // ── Sin mensajes ────────────────────────────────────────────────────────

  group('NotificationsProvider — sin mensajes', () {
    test('lastMessage se mantiene null si el stream no emite', () async {
      // Arrange
      final (provider, listenerCalls) =     createProviderWithListener();

      // Act — no emitimos nada
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(provider.lastMessage, isNull);
      expect(listenerCalls.length, equals(0));
    });
  });

  // ── R3: Foreground SnackBar callback ────────────────────────────────────

  group('NotificationsProvider — callback foreground (R3)', () {
    test('debe invocar el callback onForegroundNotification cuando llega '
        'un mensaje en foreground', () async {
      // Arrange
      RemoteMessage? capturedMessage;
      final provider = NotificationsProvider(
        mockRepo,
        onForegroundNotification: (msg) => capturedMessage = msg,
      );

      final mockMessage = MockRemoteMessage();
      final listenerCalls = <int>[];
      provider.addListener(() => listenerCalls.add(listenerCalls.length));

      // Act
      messageController.add(mockMessage);
      await Future<void>.delayed(Duration.zero);

      // Assert — el callback fue invocado con el mensaje correcto
      expect(capturedMessage, same(mockMessage));
      // Y tambien se actualizo el estado
      expect(provider.lastMessage, same(mockMessage));
      expect(listenerCalls.length, equals(1));
    });

    test(
      'debe funcionar sin callback opcional (solo actualizar estado)',
      () async {
        // Arrange — sin callback
        final (provider, listenerCalls) =     createProviderWithListener();
        final mockMessage = MockRemoteMessage();

        // Act
        messageController.add(mockMessage);
        await Future<void>.delayed(Duration.zero);

        // Assert — el estado se actualiza normalmente
        expect(provider.lastMessage, same(mockMessage));
        expect(listenerCalls.length, equals(1));
      },
    );
  });
}
