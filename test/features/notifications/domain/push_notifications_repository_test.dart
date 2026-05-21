// TDD: RED → GREEN → REFACTOR — test de contrato para cada metodo
// de la interfaz PushNotificationsRepository.
//
// Verifica que PushNotificationsRepository sea implementable con mocktail
// y que las firmas de sus 5 metodos coincidan con el spec R1-R4.
//
// Capas de test:
// - Contrato (5 tests): verifica tipos de retorno y firma de cada metodo.
// - Triangulacion (4 tests): valores alternativos y streams con mensajes reales.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/notifications/domain/push_notifications_repository.dart';

// Mock de NotificationSettings — no tiene constructor publico accesible.
class MockNotificationSettings extends Mock implements NotificationSettings {}

// Mock de RemoteMessage para tests de streams.
class MockRemoteMessage extends Mock implements RemoteMessage {}

class MockPushNotificationsRepository extends Mock
    implements PushNotificationsRepository {}

void main() {
  late MockPushNotificationsRepository mockRepo;

  setUp(() {
    mockRepo = MockPushNotificationsRepository();
  });

  group('PushNotificationsRepository — contrato de dominio', () {
    // R1: subscribeToTopic
    test(
      'subscribeToTopic debe aceptar un String y retornar Future<bool>',
      () async {
        // Arrange
        const topic = 'app-updates';
        when(
          () => mockRepo.subscribeToTopic(any()),
        ).thenAnswer((_) async => true);

        // Act
        final result = await mockRepo.subscribeToTopic(topic);

        // Assert
        expect(result, isTrue);
        verify(() => mockRepo.subscribeToTopic(topic)).called(1);
      },
    );

    // R2: requestPermission
    test(
      'requestPermission debe retornar Future<NotificationSettings>',
      () async {
        // Arrange — mock de NotificationSettings porque no tiene constructor
        // publico. Mocktail permite stubbear las propiedades individualmente.
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);
        when(
          () => mockRepo.requestPermission(),
        ).thenAnswer((_) async => mockSettings);

        // Act
        final result = await mockRepo.requestPermission();

        // Assert
        expect(result.authorizationStatus, AuthorizationStatus.authorized);
        verify(() => mockRepo.requestPermission()).called(1);
      },
    );

    // R3: onMessage (foreground stream)
    test('onMessage debe exponer un Stream<RemoteMessage>', () {
      // Arrange
      final controller = StreamController<RemoteMessage>.broadcast();
      when(() => mockRepo.onMessage).thenAnswer((_) => controller.stream);

      // Act
      final stream = mockRepo.onMessage;

      // Assert
      expect(stream, isA<Stream<RemoteMessage>>());
      controller.close();
    });

    // R3: onMessageOpenedApp (background → foreground stream)
    test('onMessageOpenedApp debe exponer un Stream<RemoteMessage>', () {
      // Arrange
      final controller = StreamController<RemoteMessage>.broadcast();
      when(
        () => mockRepo.onMessageOpenedApp,
      ).thenAnswer((_) => controller.stream);

      // Act
      final stream = mockRepo.onMessageOpenedApp;

      // Assert
      expect(stream, isA<Stream<RemoteMessage>>());
      controller.close();
    });

    // R4: getInitialMessage (app terminada → abierta)
    test('getInitialMessage debe retornar Future<RemoteMessage?>', () async {
      // Arrange — null cuando no hay mensaje pendiente
      when(() => mockRepo.getInitialMessage()).thenAnswer((_) async => null);

      // Act
      final result = await mockRepo.getInitialMessage();

      // Assert
      expect(result, isNull);
      verify(() => mockRepo.getInitialMessage()).called(1);
    });

    // TRIANGULATE R1: subscribeToTopic con fallo
    test('subscribeToTopic debe retornar false cuando FCM rechaza la '
        'suscripcion', () async {
      // Arrange
      when(
        () => mockRepo.subscribeToTopic(any()),
      ).thenAnswer((_) async => false);

      // Act
      final result = await mockRepo.subscribeToTopic('topic-inexistente');

      // Assert
      expect(result, isFalse);
    });

    // TRIANGULATE R2: requestPermission con permiso denegado
    test(
      'requestPermission debe reflejar AuthorizationStatus.denied',
      () async {
        // Arrange
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.denied);
        when(
          () => mockRepo.requestPermission(),
        ).thenAnswer((_) async => mockSettings);

        // Act
        final result = await mockRepo.requestPermission();

        // Assert
        expect(result.authorizationStatus, AuthorizationStatus.denied);
      },
    );

    // TRIANGULATE R3: onMessage entrega mensajes reales por el stream
    test('onMessage debe entregar RemoteMessage cuando FCM envia notificacion '
        'en foreground', () async {
      // Arrange
      final controller = StreamController<RemoteMessage>.broadcast();
      final mockMessage = MockRemoteMessage();
      when(() => mockRepo.onMessage).thenAnswer((_) => controller.stream);

      // Act — escuchar el stream
      final received = <RemoteMessage>[];
      final subscription = mockRepo.onMessage.listen(received.add);

      // Emitir mensaje mock
      controller.add(mockMessage);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(received, hasLength(1));
      expect(received.first, same(mockMessage));

      await subscription.cancel();
      await controller.close();
    });

    // TRIANGULATE R4: getInitialMessage con mensaje pendiente
    test('getInitialMessage debe retornar RemoteMessage cuando la app fue '
        'abierta desde una notificacion', () async {
      // Arrange
      final mockMessage = MockRemoteMessage();
      when(
        () => mockRepo.getInitialMessage(),
      ).thenAnswer((_) async => mockMessage);

      // Act
      final result = await mockRepo.getInitialMessage();

      // Assert
      expect(result, same(mockMessage));
    });
  });
}
