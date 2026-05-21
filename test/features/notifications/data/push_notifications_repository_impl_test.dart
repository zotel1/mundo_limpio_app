// TDD: RED — test escrito ANTES que la implementacion.
//
// Pruebas unitarias para PushNotificationsRepositoryImpl.
// Verifica que cada metodo delega correctamente a FirebaseMessaging
// y que los streams (static getters) se exponen sin intermediarios.
//
// Escenarios del spec R1-R4:
// - R1: subscribeToTopic retorna true en exito, false en fallo.
// - R2: requestPermission delega a FirebaseMessaging y retorna NotificationSettings.
// - R3: onMessage y onMessageOpenedApp exponen los streams estaticos de FCM.
// - R4: getInitialMessage delega a la instancia y puede retornar null.
//
// Capa de test: Unit — mocktail mock de FirebaseMessaging.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// La implementacion NO existe aun — este import fallara en analisis
// hasta que se cree el archivo en la fase GREEN.
import 'package:mundo_limpio_app/features/notifications/data/push_notifications_repository_impl.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

// FirebaseMessaging no es final — mocktail puede mockearlo via noSuchMethod.
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

// NotificationSettings no tiene constructor publico — mockeamos via Mock.
class MockNotificationSettings extends Mock implements NotificationSettings {}

// RemoteMessage no tiene constructor publico — mockeamos via Mock.
class MockRemoteMessage extends Mock implements RemoteMessage {}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late MockFirebaseMessaging mockMessaging;
  late PushNotificationsRepositoryImpl repo;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    repo = PushNotificationsRepositoryImpl(messaging: mockMessaging);

    // Stubs por defecto para metodos asincronos de FirebaseMessaging
    when(() => mockMessaging.subscribeToTopic(any())).thenAnswer((_) async {});
    when(
      () => mockMessaging.requestPermission(),
    ).thenAnswer((_) async => MockNotificationSettings());
    when(() => mockMessaging.getInitialMessage()).thenAnswer((_) async => null);
  });

  // ── R1: subscribeToTopic ────────────────────────────────────────────────

  group('subscribeToTopic — R1 (suscripcion a topic FCM)', () {
    test('debe delegar a FirebaseMessaging y retornar true en exito', () async {
      // Arrange
      const topic = 'app-updates';
      when(
        () => mockMessaging.subscribeToTopic(any()),
      ).thenAnswer((_) async {});

      // Act
      final result = await repo.subscribeToTopic(topic);

      // Assert
      expect(result, isTrue);
      verify(() => mockMessaging.subscribeToTopic(topic)).called(1);
    });

    test(
      'debe retornar false cuando FirebaseMessaging lanza excepcion',
      () async {
        // Arrange
        const topic = 'topic-roto';
        when(
          () => mockMessaging.subscribeToTopic(any()),
        ).thenThrow(Exception('FCM no disponible'));

        // Act
        final result = await repo.subscribeToTopic(topic);

        // Assert
        expect(result, isFalse);
        verify(() => mockMessaging.subscribeToTopic(topic)).called(1);
      },
    );

    // TRIANGULATE: verifica que el topic se pasa correctamente
    test('debe pasar el topic exacto a FirebaseMessaging', () async {
      // Arrange
      const topic = 'promociones-especiales';
      when(
        () => mockMessaging.subscribeToTopic(any()),
      ).thenAnswer((_) async {});

      // Act
      await repo.subscribeToTopic(topic);

      // Assert
      verify(() => mockMessaging.subscribeToTopic(topic)).called(1);
    });

    // TRIANGULATE: verifica que topic vacio no crashea
    test('debe manejar topic vacio sin crashear', () async {
      // Arrange
      const topic = '';
      when(
        () => mockMessaging.subscribeToTopic(any()),
      ).thenAnswer((_) async {});

      // Act
      final result = await repo.subscribeToTopic(topic);

      // Assert
      expect(result, isTrue);
      verify(() => mockMessaging.subscribeToTopic(topic)).called(1);
    });
  });

  // ── R2: requestPermission ───────────────────────────────────────────────

  group('requestPermission — R2 (solicitud de permiso)', () {
    test(
      'debe delegar a FirebaseMessaging y retornar NotificationSettings',
      () async {
        // Arrange
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);
        when(
          () => mockMessaging.requestPermission(),
        ).thenAnswer((_) async => mockSettings);

        // Act
        final result = await repo.requestPermission();

        // Assert
        expect(result.authorizationStatus, AuthorizationStatus.authorized);
        verify(() => mockMessaging.requestPermission()).called(1);
      },
    );

    // TRIANGULATE: permiso denegado
    test(
      'debe reflejar AuthorizationStatus.denied cuando el usuario rechaza',
      () async {
        // Arrange
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.denied);
        when(
          () => mockMessaging.requestPermission(),
        ).thenAnswer((_) async => mockSettings);

        // Act
        final result = await repo.requestPermission();

        // Assert
        expect(result.authorizationStatus, AuthorizationStatus.denied);
      },
    );

    // TRIANGULATE: permiso provisional (iOS)
    test('debe reflejar AuthorizationStatus.provisional en iOS', () async {
      // Arrange
      final mockSettings = MockNotificationSettings();
      when(
        () => mockSettings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.provisional);
      when(
        () => mockMessaging.requestPermission(),
      ).thenAnswer((_) async => mockSettings);

      // Act
      final result = await repo.requestPermission();

      // Assert
      expect(result.authorizationStatus, AuthorizationStatus.provisional);
    });
  });

  // ── R3: onMessage (foreground stream) ───────────────────────────────────

  group('onMessage — R3 (stream foreground)', () {
    test('debe exponer un Stream<RemoteMessage> no nulo', () {
      // Arrange — no hay mockeo posible porque onMessage es static getter
      // en FirebaseMessaging. FirebaseMessaging.onMessage crea una nueva
      // instancia de stream en cada acceso (platform channel), asi que
      // verificamos tipo y no-nulidad en vez de identidad.

      // Act
      final repoStream = repo.onMessage;

      // Assert
      expect(repoStream, isNotNull);
      expect(repoStream, isA<Stream<RemoteMessage>>());
    });
  });

  // ── R3: onMessageOpenedApp (background → foreground stream) ─────────────

  group('onMessageOpenedApp — R3 (stream background)', () {
    test('debe exponer un Stream<RemoteMessage> no nulo', () {
      // Arrange — mismo patron que onMessage: static getter sin mockeo.
      // FirebaseMessaging.onMessageOpenedApp crea una nueva instancia
      // de stream en cada acceso (platform channel binding).

      // Act
      final repoStream = repo.onMessageOpenedApp;

      // Assert
      expect(repoStream, isNotNull);
      expect(repoStream, isA<Stream<RemoteMessage>>());
    });
  });

  // ── R4: getInitialMessage ──────────────────────────────────────────────

  group('getInitialMessage — R4 (app abierta desde notificacion)', () {
    test('debe delegar a FirebaseMessaging y retornar null cuando no hay '
        'mensaje pendiente', () async {
      // Arrange
      when(
        () => mockMessaging.getInitialMessage(),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repo.getInitialMessage();

      // Assert
      expect(result, isNull);
      verify(() => mockMessaging.getInitialMessage()).called(1);
    });

    // TRIANGULATE: mensaje pendiente
    test('debe retornar RemoteMessage cuando la app fue abierta desde una '
        'notificacion', () async {
      // Arrange
      final mockMessage = MockRemoteMessage();
      when(
        () => mockMessaging.getInitialMessage(),
      ).thenAnswer((_) async => mockMessage);

      // Act
      final result = await repo.getInitialMessage();

      // Assert
      expect(result, same(mockMessage));
      verify(() => mockMessaging.getInitialMessage()).called(1);
    });
  });
}
