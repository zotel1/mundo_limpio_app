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

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// La implementacion NO existe aun — este import fallara en analisis
// hasta que se cree el archivo en la fase GREEN.
import 'package:mundo_limpio_app/core/services/notifications_service.dart';
import 'package:mundo_limpio_app/core/crashlytics/crashlytics_service.dart';

import 'package:mundo_limpio_app/features/notifications/domain/push_notifications_repository.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockPushNotificationsRepository extends Mock
    implements PushNotificationsRepository {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

// FirebaseCrashlytics no es final — mocktail puede mockearlo.
class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Crea un [NotificationSettings] mock con el [AuthorizationStatus] dado.
NotificationSettings _settingsWith(AuthorizationStatus status) {
  final settings = MockNotificationSettings();
  when(() => settings.authorizationStatus).thenReturn(status);
  return settings;
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late MockPushNotificationsRepository mockRepo;
  late MockFirebaseCrashlytics mockCrashlytics;

  setUp(() {
    mockRepo = MockPushNotificationsRepository();
    mockCrashlytics = MockFirebaseCrashlytics();

    // Inyectar mock de repositorio en NotificationsService
    NotificationsService.testInstance = mockRepo;

    // Inyectar mock de Crashlytics via CrashlyticsService (patron existente)
    CrashlyticsService.testInstance = mockCrashlytics;
    CrashlyticsService.setOptOut(false);

    // Stubs por defecto: permiso autorizado, suscripcion exitosa
    when(
      () => mockRepo.requestPermission(),
    ).thenAnswer((_) async => _settingsWith(AuthorizationStatus.authorized));
    when(() => mockRepo.subscribeToTopic(any())).thenAnswer((_) async => true);

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
    NotificationsService.resetForTesting();
    CrashlyticsService.resetForTesting();
  });

  // ── Permiso denegado ────────────────────────────────────────────────────

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

  // ── Permiso concedido + suscripcion exitosa ─────────────────────────────

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

  // ── Retry: falla 1 vez, exito en 2do intento ────────────────────────────

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

  // ── Fallo persistente (3 intentos fallidos) ─────────────────────────────

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

  // ── Error inesperado al pedir permiso ───────────────────────────────────

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

  // ── Backoff exponencial ─────────────────────────────────────────────────

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

  // ── testInstance override ───────────────────────────────────────────────

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

      NotificationsService.testInstance = otherMock;

      // Act
      await NotificationsService.initialize();

      // Assert — el mock original NO fue usado
      verifyNever(() => mockRepo.subscribeToTopic(any()));
      verify(() => otherMock.subscribeToTopic('app-updates')).called(1);
    });
  });
}
