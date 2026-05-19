// Pruebas unitarias para CrashlyticsService.
//
// Como CrashlyticsService usa Firebase nativo (no mockeable en entorno de test),
// los tests se enfocan en la lógica pura de Dart:
// - Opt-out: setOptOut(true) evita que recordError llame a Firebase
// - Opt-out desactivado: recordError sí llama a Firebase
// - setUser: verifica que setUserIdentifier + setCustomKey se invocan
// - Inicialización: los handlers de error se configuran
//
// TDD: RED — tests escritos ANTES de la implementación

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/crashlytics/crashlytics_service.dart';

// Mock de FirebaseCrashlytics usando mocktail.
// FirebaseCrashlytics no es final — mocktail puede mockearlo via noSuchMethod.
class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late MockFirebaseCrashlytics mockCrashlytics;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();

    // Inyectar el mock en el servicio para tests
    CrashlyticsService.testInstance = mockCrashlytics;

    // Desactivar opt-out por defecto (comportamiento normal de producción)
    CrashlyticsService.setOptOut(false);

    // Stubs por defecto para métodos void/async de FirebaseCrashlytics
    when(
      () => mockCrashlytics.setUserIdentifier(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockCrashlytics.setCustomKey(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () =>
          mockCrashlytics.recordError(any(), any(), fatal: any(named: 'fatal')),
    ).thenAnswer((_) async {});
    when(() => mockCrashlytics.log(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    // Restaurar estado limpio entre tests
    CrashlyticsService.resetForTesting();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Opt-out
  // ──────────────────────────────────────────────────────────────────────────

  group('Opt-out — setOptOut(true)', () {
    test(
      'recordError NO debe llamar a Firebase cuando opt-out está activado',
      () {
        // TDD: RED — CrashlyticsService y setOptOut aún no existen
        CrashlyticsService.setOptOut(true);

        CrashlyticsService.recordError(
          Exception('Error de prueba'),
          StackTrace.current,
        );

        // Verifica que recordError de Firebase NUNCA fue llamado
        verifyNever(
          () => mockCrashlytics.recordError(
            any(),
            any(),
            fatal: any(named: 'fatal'),
          ),
        );
      },
    );

    test(
      'recordError con solo exception (sin stack) no llama a Firebase con opt-out',
      () {
        CrashlyticsService.setOptOut(true);

        CrashlyticsService.recordError('Error string sin stack');

        verifyNever(
          () => mockCrashlytics.recordError(
            any(),
            any(),
            fatal: any(named: 'fatal'),
          ),
        );
      },
    );
  });

  group('Opt-out — setOptOut(false)', () {
    test(
      'recordError DEBE llamar a Firebase.recordError cuando opt-out está desactivado',
      () {
        // TDD: RED — comportamiento normal (sin opt-out) sí reporta
        CrashlyticsService.setOptOut(false);

        final exception = Exception('Error real');
        final stack = StackTrace.current;

        CrashlyticsService.recordError(exception, stack);

        verify(
          () => mockCrashlytics.recordError(exception, stack, fatal: false),
        ).called(1);
      },
    );

    test('recordError sin stack pasa fatal: false por defecto', () {
      CrashlyticsService.setOptOut(false);

      CrashlyticsService.recordError('Error sin stack');

      verify(
        () => mockCrashlytics.recordError(
          'Error sin stack',
          any<StackTrace?>(),
          fatal: false,
        ),
      ).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // setUser
  // ──────────────────────────────────────────────────────────────────────────

  group('setUser', () {
    test(
      'debe llamar setUserIdentifier con el userId y setCustomKey con role',
      () {
        // TDD: RED — setUser configura metadata de Crashlytics
        CrashlyticsService.setUser('operador123', 'operator');

        verify(
          () => mockCrashlytics.setUserIdentifier('operador123'),
        ).called(1);
        verify(
          () => mockCrashlytics.setCustomKey('role', 'operator'),
        ).called(1);
      },
    );

    test('debe funcionar con role "admin"', () {
      CrashlyticsService.setUser('admin99', 'admin');

      verify(() => mockCrashlytics.setUserIdentifier('admin99')).called(1);
      verify(() => mockCrashlytics.setCustomKey('role', 'admin')).called(1);
    });

    test('debe funcionar con userId vacío sin romperse', () {
      // Caso borde: userId vacío es válido (no debería crashear)
      CrashlyticsService.setUser('', 'operator');

      verify(() => mockCrashlytics.setUserIdentifier('')).called(1);
      verify(() => mockCrashlytics.setCustomKey('role', 'operator')).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Toggle opt-out
  // ──────────────────────────────────────────────────────────────────────────

  group('setOptOut toggle', () {
    test('al desactivar opt-out, recordError vuelve a reportar', () {
      // Activar opt-out → recordError no reporta
      CrashlyticsService.setOptOut(true);
      CrashlyticsService.recordError('error silenciado');
      verifyNever(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          fatal: any(named: 'fatal'),
        ),
      );

      // Desactivar opt-out → siguiente recordError SÍ reporta
      CrashlyticsService.setOptOut(false);
      CrashlyticsService.recordError('error reportado');

      verify(
        () => mockCrashlytics.recordError(
          'error reportado',
          any<StackTrace?>(),
          fatal: false,
        ),
      ).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Inicialización: FlutterError.onError
  // ──────────────────────────────────────────────────────────────────────────

  group('initialize — FlutterError.onError', () {
    test(
      'debe configurar FlutterError.onError para capturar errores fatales',
      () async {
        // Guardar el handler original para restaurarlo después
        final originalHandler = FlutterError.onError;

        try {
          await CrashlyticsService.initialize();

          // FlutterError.onError debe haber sido reemplazado
          expect(FlutterError.onError, isNot(originalHandler));
          expect(FlutterError.onError, isNotNull);
        } finally {
          FlutterError.onError = originalHandler;
        }
      },
    );
  });
}
