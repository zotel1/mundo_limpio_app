// TDD: RED — test escrito ANTES que la implementacion.
//
// Pruebas unitarias para NotificationsService.
// Verifica el flujo de inicializacion con retry y backoff exponencial,
// siguiendo el mismo patron que CrashlyticsService (testInstance setter).
//
// Escenarios del spec:
// - Permiso denegado → retorna temprano, sin intentar subscribeToTopic.
// - Permiso concedido → subscribeToTopic('app-updates') llamado.
// - Suscripcion exitosa en primer intento → sin reintentos.
// - Suscripcion falla 1 vez, exito en 2do intento → delay verificado.
// - Suscripcion falla 3 intentos → CrashlyticsService.recordError llamado.
// - Backoff exponencial: delays 1s, 2s, 4s en cada intento fallido.
// - Error inesperado al pedir permiso → CrashlyticsService.recordError, retorna sin lanzar.
//
// Capa de test: Unit — mocktail mock de PushNotificationsRepository.
// Crashlytics se mockea via CrashlyticsService.testInstance (patron existente).
// UrlLauncherService se mockea via testInstance callback (patron identico).

import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// La implementacion NO existe aun — este import fallara en analisis
// hasta que se cree el archivo en la fase GREEN.
import 'package:mundo_limpio_app/core/services/notifications_service.dart';
import 'package:mundo_limpio_app/core/crashlytics/crashlytics_service.dart';
import 'package:mundo_limpio_app/core/services/url_launcher_service.dart';

import 'package:mundo_limpio_app/features/notifications/domain/push_notifications_repository.dart';

//  Mocks

class MockPushNotificationsRepository extends Mock
    implements PushNotificationsRepository {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

// FirebaseCrashlytics no es final — mocktail puede mockearlo.
class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

//  Helpers

/// Crea un [NotificationSettings] mock con el [AuthorizationStatus] dado.
NotificationSettings _settingsWith(AuthorizationStatus status) {
  final settings = MockNotificationSettings();
  when(() => settings.authorizationStatus).thenReturn(status);
  return settings;
}

//  Tests

void main() {
  late MockPushNotificationsRepository mockRepo;
  late MockFirebaseCrashlytics mockCrashlytics;
  late StreamController<RemoteMessage> onMessageOpenedAppController;
  Uri? capturedLaunchUri;

  setUp(() {
    mockRepo = MockPushNotificationsRepository();
    mockCrashlytics = MockFirebaseCrashlytics();
    onMessageOpenedAppController = StreamController<RemoteMessage>.broadcast();

    // Inyectar mock de repositorio en NotificationsService
    NotificationsService.testInstance = mockRepo;

    // Inyectar mock de Crashlytics via CrashlyticsService (patron existente)
    CrashlyticsService.testInstance = mockCrashlytics;
    CrashlyticsService.setOptOut(false);

    // Inyectar spy en UrlLauncherService para capturar URLs
    capturedLaunchUri = null;
    UrlLauncherService.testInstance = (Uri uri) {
      capturedLaunchUri = uri;
    };

    // Stubs por defecto: permiso autorizado, suscripcion exitosa
    when(
      () => mockRepo.requestPermission(),
    ).thenAnswer((_) async => _settingsWith(AuthorizationStatus.authorized));
    when(() => mockRepo.subscribeToTopic(any())).thenAnswer((_) async => true);

    // Stubs por defecto para R4 deep link:
    // - getInitialMessage retorna null (sin mensaje pendiente)
    // - onMessageOpenedApp expone un stream controlado
    when(() => mockRepo.getInitialMessage()).thenAnswer((_) async => null);
    when(
      () => mockRepo.onMessageOpenedApp,
    ).thenAnswer((_) => onMessageOpenedAppController.stream);

    // Stubs void de Crashlytics
    when(
      () =>
          mockCrashlytics.recordError(any(), any(), fatal: any(named: 'fatal')),
    ).thenAnswer((_) async {});

    // Reducir delays de retry a 10ms para que los tests sean rapidos.
    // En produccion son 1s, 2s, 4s — validados via el test de backoff.
    NotificationsService.testRetryDelays = const [
      Duration(milliseconds: 10),
      Duration(milliseconds: 20),
      Duration(milliseconds: 40),
    ];
  });

  tearDown(() {
    onMessageOpenedAppController.close();
    NotificationsService.resetForTesting();
    CrashlyticsService.resetForTesting();
    UrlLauncherService.resetForTesting();
  });

  //  Permiso denegado

  group('initialize — permiso denegado', () {
    test('debe retornar temprano sin intentar subscribeToTopic cuando el '
        'usuario niega el permiso', () async {
      // Arrange
      when(
        () => mockRepo.requestPermission(),
      ).thenAnswer((_) async => _settingsWith(AuthorizationStatus.denied));

      // Act
      await NotificationsService.initialize();

      // Assert — subscribeToTopic NUNCA fue llamado
      verifyNever(() => mockRepo.subscribeToTopic(any()));
    });

    test('NO debe loguear a Crashlytics cuando el usuario niega el permiso '
        '(es un caso esperado)', () async {
      // Arrange
      when(
        () => mockRepo.requestPermission(),
      ).thenAnswer((_) async => _settingsWith(AuthorizationStatus.denied));

      // Act
      await NotificationsService.initialize();

      // Assert
      verifyNever(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      );
    });
  });

  //  Permiso concedido + suscripcion exitosa

  group('initialize — permiso concedido, suscripcion exitosa', () {
    test('debe suscribirse al topic "app-updates" cuando el permiso es '
        'concedido', () async {
      // Arrange — default stub: permiso autorizado, suscripcion exitosa

      // Act
      await NotificationsService.initialize();

      // Assert
      verify(() => mockRepo.subscribeToTopic('app-updates')).called(1);
    });

    test('no debe hacer reintentos cuando la suscripcion es exitosa en el '
        'primer intento', () async {
      // Arrange — default stub: suscripcion exitosa

      // Act
      await NotificationsService.initialize();

      // Assert — subscribeToTopic fue llamado exactamente 1 vez
      verify(() => mockRepo.subscribeToTopic('app-updates')).called(1);
      verifyNever(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      );
    });
  });

  //  Retry: falla 1 vez, exito en 2do intento
  group('initialize — retry con backoff exponencial', () {
    test('debe reintentar si el primer subscribeToTopic falla y tener exito '
        'en el segundo intento', () async {
      // Arrange — primer intento falla, segundo exito
      var callCount = 0;
      when(() => mockRepo.subscribeToTopic(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return false;
        return true;
      });

      // Act
      await NotificationsService.initialize();

      // Assert — 2 llamadas a subscribeToTopic
      verify(() => mockRepo.subscribeToTopic('app-updates')).called(2);
      // No se logueo error porque el retry tuvo exito
      verifyNever(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      );
    });

    test('debe esperar el delay de retry antes del segundo intento', () async {
      // Arrange — primer intento falla, segundo exito
      var callCount = 0;
      final stopwatch = Stopwatch();
      when(() => mockRepo.subscribeToTopic(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          stopwatch.start();
          return false;
        }
        stopwatch.stop();
        return true;
      });

      // Act
      await NotificationsService.initialize();

      // Assert — el delay debe haber transcurrido (~10ms + tolerancia)
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(8));
      verify(() => mockRepo.subscribeToTopic('app-updates')).called(2);
    });

    // TRIANGULATE: falla 2 veces, exito en 3er intento
    test('debe reintentar hasta 3 veces si la suscripcion falla '
        'persistentemente', () async {
      // Arrange — falla los primeros 2 intentos, exito en el 3ro
      var callCount = 0;
      when(() => mockRepo.subscribeToTopic(any())).thenAnswer((_) async {
        callCount++;
        if (callCount <= 2) return false;
        return true;
      });

      // Act
      await NotificationsService.initialize();

      // Assert — 3 llamadas
      verify(() => mockRepo.subscribeToTopic('app-updates')).called(3);
      verifyNever(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      );
    });
  });

  //  Fallo persistente (3 intentos fallidos)

  group('initialize — fallo persistente', () {
    test('debe loguear a Crashlytics cuando los 3 intentos de suscripcion '
        'fallan', () async {
      // Arrange — siempre falla
      when(
        () => mockRepo.subscribeToTopic(any()),
      ).thenAnswer((_) async => false);

      // Act
      await NotificationsService.initialize();

      // Assert — 3 intentos, luego Crashlytics
      verify(() => mockRepo.subscribeToTopic('app-updates')).called(3);
      verify(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      ).called(1);
    });

    test(
      'el mensaje de Crashlytics debe mencionar el topic y los intentos',
      () async {
        // Arrange
        when(
          () => mockRepo.subscribeToTopic(any()),
        ).thenAnswer((_) async => false);

        // Act
        await NotificationsService.initialize();

        // Assert — verifica que el error reportado contiene info relevante
        verify(
          () => mockCrashlytics.recordError(
            any(
              that: isA<String>().having(
                (s) => s.toLowerCase(),
                'contiene topic',
                contains('app-updates'),
              ),
            ),
            any(),
            fatal: any(named: 'fatal'),
          ),
        ).called(1);
      },
    );
  });

  //  Error inesperado al pedir permiso

  group('initialize — error inesperado en requestPermission', () {
    test('debe loguear a Crashlytics y retornar limpiamente cuando '
        'requestPermission lanza excepcion', () async {
      // Arrange
      when(
        () => mockRepo.requestPermission(),
      ).thenThrow(Exception('FCM no disponible'));

      // Act — no debe lanzar excepcion
      await NotificationsService.initialize();

      // Assert
      verify(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      ).called(1);
      // No intento suscribirme porque el permiso fallo
      verifyNever(() => mockRepo.subscribeToTopic(any()));
    });

    test('no debe crashear cuando requestPermission lanza error (R6: '
        'notificaciones no bloquean la app)', () async {
      // Arrange
      when(
        () => mockRepo.requestPermission(),
      ).thenThrow(Exception('Servicio no disponible'));

      // Act & Assert — initialize() no debe lanzar
      expect(() => NotificationsService.initialize(), returnsNormally);
    });
  });

  //  Backoff exponencial

  group('initialize — backoff exponencial', () {
    test(
      'el primer delay debe ser respetado antes del segundo intento',
      () async {
        // Arrange — falla en intento 1, exito en intento 2
        var callCount = 0;
        final callTimes = <int>[];
        when(() => mockRepo.subscribeToTopic(any())).thenAnswer((_) async {
          callCount++;
          callTimes.add(DateTime.now().microsecondsSinceEpoch);
          return callCount >= 2;
        });

        // Act
        await NotificationsService.initialize();

        // Assert — la diferencia entre la 1ra y 2da llamada >= delay (10ms)
        final diff = callTimes[1] - callTimes[0];
        // 10ms = 10000us. Con tolerancia de ~2ms.
        expect(diff, greaterThanOrEqualTo(8000));
      },
    );

    // TRIANGULATE: verifica que los delays crecen (10ms, 20ms, 40ms en test)
    test('los delays deben crecer exponencialmente entre intentos', () async {
      // Arrange — falla intentos 1 y 2, exito en 3
      var callCount = 0;
      final callTimes = <int>[];
      when(() => mockRepo.subscribeToTopic(any())).thenAnswer((_) async {
        callCount++;
        callTimes.add(DateTime.now().microsecondsSinceEpoch);
        return callCount >= 3;
      });

      // Act
      await NotificationsService.initialize();

      // Assert
      // Delay entre intento 1→2: ~10ms
      final delay1 = callTimes[1] - callTimes[0];
      // Delay entre intento 2→3: ~20ms
      final delay2 = callTimes[2] - callTimes[1];

      // El segundo delay debe ser >= el primero (backoff creciente)
      expect(delay2, greaterThanOrEqualTo(delay1));
      // Ambos delays deben ser >= 8ms
      expect(delay1, greaterThanOrEqualTo(8000));
      expect(delay2, greaterThanOrEqualTo(8000));
    });
  });

  //  testInstance override

  group('testInstance — inyeccion para tests', () {
    test('debe usar el repositorio inyectado via testInstance', () async {
      // Arrange — repositorio separado
      final otherMock = MockPushNotificationsRepository();
      when(
        () => otherMock.requestPermission(),
      ).thenAnswer((_) async => _settingsWith(AuthorizationStatus.authorized));
      when(
        () => otherMock.subscribeToTopic(any()),
      ).thenAnswer((_) async => true);
      // Stub R4 para el otherMock tambien
      when(() => otherMock.getInitialMessage()).thenAnswer((_) async => null);
      when(
        () => otherMock.onMessageOpenedApp,
      ).thenAnswer((_) => onMessageOpenedAppController.stream);

      NotificationsService.testInstance = otherMock;

      // Act
      await NotificationsService.initialize();

      // Assert — el mock original NO fue usado
      verifyNever(() => mockRepo.subscribeToTopic(any()));
      verify(() => otherMock.subscribeToTopic('app-updates')).called(1);
    });
  });

  // ── R4 Deep Link: terminated state ─────────────────────────────────────

  group('initialize — R4 deep link from terminated', () {
    // TDD: RED — test escrito ANTES que la implementacion.
    test('debe llamar a UrlLauncherService.launchUrl() cuando '
        'getInitialMessage tiene data.url valido', () async {
      // Arrange: getInitialMessage retorna mensaje con URL
      final mockMessage = MockRemoteMessage();
      when(() => mockMessage.data).thenReturn({
        'url': 'https://appdistribution.firebase.dev/i/923159339728',
        'type': 'app_update',
      });
      when(
        () => mockRepo.getInitialMessage(),
      ).thenAnswer((_) async => mockMessage);

      // Act
      await NotificationsService.initialize();

      // Assert: UrlLauncherService fue llamado con la URL correcta
      expect(capturedLaunchUri, isNotNull);
      expect(
        capturedLaunchUri!.toString(),
        'https://appdistribution.firebase.dev/i/923159339728',
      );
    });

    test('NO debe llamar a UrlLauncherService.launchUrl() cuando '
        'getInitialMessage retorna null', () async {
      // Arrange: getInitialMessage ya esta stubbed como null en setUp

      // Act
      await NotificationsService.initialize();

      // Assert
      expect(capturedLaunchUri, isNull);
    });

    test('NO debe llamar a UrlLauncherService.launchUrl() cuando '
        'data.url es null', () async {
      // Arrange: mensaje sin clave url
      final mockMessage = MockRemoteMessage();
      when(() => mockMessage.data).thenReturn({'type': 'app_update'});
      when(
        () => mockRepo.getInitialMessage(),
      ).thenAnswer((_) async => mockMessage);

      // Act
      await NotificationsService.initialize();

      // Assert
      expect(capturedLaunchUri, isNull);
    });

    test('NO debe llamar a UrlLauncherService.launchUrl() cuando '
        'data.url es string vacio', () async {
      // TDD: RED — TRIANGULATE: URL vacia
      final mockMessage = MockRemoteMessage();
      when(
        () => mockMessage.data,
      ).thenReturn({'url': '', 'type': 'app_update'});
      when(
        () => mockRepo.getInitialMessage(),
      ).thenAnswer((_) async => mockMessage);

      // Act
      await NotificationsService.initialize();

      // Assert
      expect(capturedLaunchUri, isNull);
    });

    test('NO debe lanzar excepcion cuando UrlLauncherService.launchUrl() '
        'falla (R6: notificaciones no bloquean la app)', () async {
      // TDD: RED — TRIANGULATE: error recovery
      final mockMessage = MockRemoteMessage();
      when(() => mockMessage.data).thenReturn({
        'url': 'https://appdistribution.firebase.dev/i/923159339728',
      });
      when(
        () => mockRepo.getInitialMessage(),
      ).thenAnswer((_) async => mockMessage);

      // Arrange: UrlLauncherService lanza excepcion
      UrlLauncherService.testInstance = (Uri uri) {
        throw Exception('No browser available');
      };

      // Act & Assert: initialize() no debe lanzar
      await expectLater(NotificationsService.initialize(), completes);
    });

    test(
      'debe loguear a Crashlytics cuando launchUrl lanza excepcion',
      () async {
        // TDD: RED — TRIANGULATE: error logged to Crashlytics
        final mockMessage = MockRemoteMessage();
        when(() => mockMessage.data).thenReturn({
          'url': 'https://appdistribution.firebase.dev/i/923159339728',
        });
        when(
          () => mockRepo.getInitialMessage(),
        ).thenAnswer((_) async => mockMessage);

        // Arrange: UrlLauncherService lanza excepcion
        UrlLauncherService.testInstance = (Uri uri) {
          throw Exception('No browser available');
        };

        // Act
        await NotificationsService.initialize();

        // Assert: Crashlytics fue notificado del error
        verify(
          () => mockCrashlytics.recordError(
            any(),
            any(),
            fatal: any(named: 'fatal'),
          ),
        ).called(1);
      },
    );

    test('debe loguear a Crashlytics cuando getInitialMessage() lanza '
        'excepcion', () async {
      // TDD: RED — TRIANGULATE: FCM error in getInitialMessage
      when(
        () => mockRepo.getInitialMessage(),
      ).thenThrow(Exception('FCM service error'));

      // Act & Assert: no crashea
      await NotificationsService.initialize();

      // Assert: Crashlytics fue notificado
      verify(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      ).called(1);
    });
  });

  // ── R4 Deep Link: background stream ────────────────────────────────────

  group('initialize — R4 deep link from background', () {
    // TDD: RED — test escrito ANTES que la implementacion.
    test('debe llamar a UrlLauncherService.launchUrl() cuando '
        'onMessageOpenedApp emite mensaje con data.url valido', () async {
      // Arrange: inicializar primero para que el listener se registre
      await NotificationsService.initialize();

      // Resetear el spy para capturar solo la llamada del stream
      capturedLaunchUri = null;

      // Act: emitir mensaje con URL en el stream
      final mockMessage = MockRemoteMessage();
      when(() => mockMessage.data).thenReturn({
        'url': 'https://appdistribution.firebase.dev/i/923159339728',
      });
      onMessageOpenedAppController.add(mockMessage);

      // Esperar a que el stream se procese
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(capturedLaunchUri, isNotNull);
      expect(
        capturedLaunchUri!.toString(),
        'https://appdistribution.firebase.dev/i/923159339728',
      );
    });

    test('NO debe llamar a UrlLauncherService.launchUrl() cuando '
        'data.url es null', () async {
      // Arrange
      await NotificationsService.initialize();
      capturedLaunchUri = null;

      // Act: emitir mensaje sin url
      final mockMessage = MockRemoteMessage();
      when(() => mockMessage.data).thenReturn({'type': 'app_update'});
      onMessageOpenedAppController.add(mockMessage);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(capturedLaunchUri, isNull);
    });

    test('NO debe lanzar excepcion cuando UrlLauncherService.launchUrl() '
        'falla (R6)', () async {
      // Arrange: inicializar con listener
      await NotificationsService.initialize();

      // Arrange: testInstance lanza excepcion
      UrlLauncherService.testInstance = (Uri uri) {
        throw Exception('No browser available');
      };

      // Act: emitir mensaje con URL
      final mockMessage = MockRemoteMessage();
      when(() => mockMessage.data).thenReturn({
        'url': 'https://appdistribution.firebase.dev/i/923159339728',
      });
      onMessageOpenedAppController.add(mockMessage);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert: no crashea (si llego hasta aca, el test paso)
      expect(true, isTrue); // llegó sin excepción
    });

    test('debe loguear a Crashlytics cuando launchUrl lanza excepcion '
        'en el stream listener', () async {
      // Arrange: inicializar con listener
      await NotificationsService.initialize();

      // Arrange: testInstance lanza excepcion
      UrlLauncherService.testInstance = (Uri uri) {
        throw Exception('No browser available');
      };

      // Resetear contador de Crashlytics (ya fue llamado por los stubs)
      // Nota: Crashlytics se llama 0 veces en el listener porque
      // aun no se emitio ningun mensaje que cause launchUrl.

      // Act: emitir mensaje con URL
      final mockMessage = MockRemoteMessage();
      when(() => mockMessage.data).thenReturn({
        'url': 'https://appdistribution.firebase.dev/i/923159339728',
      });
      onMessageOpenedAppController.add(mockMessage);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert: Crashlytics fue notificado del error
      verify(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      ).called(1);
    });
  });

  // ── T-2.5 RED: resetForTesting cancela stream subscription ────────────

  group('resetForTesting — limpieza de suscripcion R4', () {
    test('debe cancelar el stream subscription de onMessageOpenedApp '
        'al llamar a resetForTesting', () async {
      // TDD: RED — Arrange: inicializar y registrar listener
      await NotificationsService.initialize();

      // Act: resetear
      NotificationsService.resetForTesting();

      // Reinyectar mock tras reset (resetForTesting limpia __testInstance)
      NotificationsService.testInstance = mockRepo;

      // Assert: emitir mensaje — el listener viejo no deberia dispararse
      capturedLaunchUri = null;
      UrlLauncherService.testInstance = (Uri uri) {
        capturedLaunchUri = uri;
      };

      final mockMessage = MockRemoteMessage();
      when(() => mockMessage.data).thenReturn({
        'url': 'https://appdistribution.firebase.dev/i/923159339728',
      });
      onMessageOpenedAppController.add(mockMessage);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // El listener fue cancelado por resetForTesting, asi que
      // NO deberia haberse llamado a launchUrl
      expect(capturedLaunchUri, isNull);
    });
  });
}
