// Pruebas unitarias para SplashProvider.
//
// Verifica la máquina de estados idle→waking→retry→resolved:
// - Estado inicial idle
// - Tap (startWaking) transiciona a waking
// - Wake OK + animación + auth → resolved
// - Wake falla → retry
// - Tap en retry → waking nuevamente
// - Auto-auth: ya autenticado, onAuthResolved antes del wake
// - Callback _onStateChanged notifica a GoRouter
// - notifyListeners se llama en cada transición
//
// TDD: RED — test escrito antes que la implementación

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/splash/domain/splash_repository.dart';
import 'package:mundo_limpio_app/features/splash/domain/splash_state.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_provider.dart';

// Mock del repositorio para aislar el provider de la capa de datos
class MockSplashRepository extends Mock implements SplashRepository {}

/// Helper: espera que el event loop procese timers pendientes.
///
/// Con [animationDuration] = Duration.zero, el Timer se dispara
/// en el siguiente ciclo del event loop. Este helper da tiempo
/// suficiente para que los callbacks se ejecuten.
Future<void> pumpEventQueue({int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late MockSplashRepository mockRepo;
  late SplashProvider provider;

  setUp(() {
    mockRepo = MockSplashRepository();
    provider = SplashProvider(
      mockRepo,
      // Duración cero para tests: el timer se dispara inmediatamente
      animationDuration: Duration.zero,
    );

    // Stub por defecto: wakeBackend retorna true (backend saludable)
    when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);
  });

  group('estado inicial', () {
    test('debe iniciar en estado idle', () {
      expect(provider.state, SplashState.idle);
    });

    test('isIdle debe ser true al iniciar', () {
      expect(provider.isIdle, isTrue);
    });

    test('isWaking debe ser false al iniciar', () {
      expect(provider.isWaking, isFalse);
    });

    test('isRetry debe ser false al iniciar', () {
      expect(provider.isRetry, isFalse);
    });

    test('isResolved debe ser false al iniciar', () {
      expect(provider.isResolved, isFalse);
    });

    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });
  });

  group('startWaking — idle → waking', () {
    test('debe transicionar a waking al llamar startWaking', () async {
      // Arrange: mock wakeBackend con un Completer para que no se resuelva aún
      final completer = Completer<bool>();
      when(() => mockRepo.wakeBackend()).thenAnswer((_) => completer.future);

      // Act
      provider.startWaking();

      // Assert: transición inmediata a waking (síncrono)
      expect(provider.state, SplashState.waking);
      expect(provider.isWaking, isTrue);

      // Cleanup: liberar el completer
      completer.complete(true);
      await pumpEventQueue();
    });

    test('debe llamar wakeBackend del repositorio', () async {
      provider.startWaking();

      verify(() => mockRepo.wakeBackend()).called(1);
    });

    test('debe notificar listeners en la transición a waking', () async {
      final completer = Completer<bool>();
      when(() => mockRepo.wakeBackend()).thenAnswer((_) => completer.future);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.startWaking();

      // startWaking llama notifyListeners al setear waking
      expect(notifyCount, greaterThanOrEqualTo(1));

      completer.complete(true);
      await pumpEventQueue();
    });
  });

  group('wake OK + auth → resolved', () {
    test(
      'debe transicionar a resolved cuando wake OK, animación lista y auth resuelto',
      () async {
        // Arrange: mock wakeBackend retorna true (stub por defecto)

        // Act: iniciar el despertar y marcar auth como resuelto
        provider.startWaking();
        provider.onAuthResolved();

        // Esperar que los callbacks se procesen (timer + wake result)
        await pumpEventQueue();

        // Assert
        expect(provider.state, SplashState.resolved);
        expect(provider.isResolved, isTrue);
      },
    );

    test('debe llamar notifyListeners en la transición a resolved', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.startWaking();
      provider.onAuthResolved();
      await pumpEventQueue();

      // Al menos 2 notificaciones: idle→waking, waking→resolved
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('wake fail → retry', () {
    test('debe transicionar a retry cuando el backend no responde', () async {
      // Arrange: mock wakeBackend retorna false (backend caído)
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => false);

      // Act
      provider.startWaking();
      await pumpEventQueue();

      // Assert
      expect(provider.state, SplashState.retry);
      expect(provider.isRetry, isTrue);
    });

    test(
      'debe transicionar a retry cuando el backend lanza excepción',
      () async {
        // Arrange: simular error de red con Future que falla
        // (usamos thenAnswer async throw en vez de thenThrow
        //  porque thenThrow lanza síncrono, y queremos probar
        //  que el provider lo captura sin re-lanzar)
        when(
          () => mockRepo.wakeBackend(),
        ).thenAnswer((_) async => throw Exception('Red caída'));

        // Act: NO debe lanzar
        provider.startWaking();
        await pumpEventQueue();

        // Assert
        expect(provider.state, SplashState.retry);
      },
    );

    test('debe llamar notifyListeners en transición a retry', () async {
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => false);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.startWaking();
      await pumpEventQueue();

      // Al menos 2: idle→waking, waking→retry
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('retry tap → waking', () {
    test('debe volver a waking al reintentar desde retry', () async {
      // Arrange: forzar estado retry primero
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => false);
      provider.startWaking();
      await pumpEventQueue();
      expect(provider.state, SplashState.retry);

      // Arrange: ahora el backend responde
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);

      // Act: reintentar (tap en retry)
      provider.startWaking();
      provider.onAuthResolved();
      await pumpEventQueue();

      // Assert: pasó de retry → waking → resolved
      expect(provider.state, SplashState.resolved);
    });

    test('debe permitir reintentar múltiples veces', () async {
      // Primer intento: falla
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => false);
      provider.startWaking();
      await pumpEventQueue();
      expect(provider.state, SplashState.retry);

      // Segundo intento: también falla
      provider.startWaking();
      await pumpEventQueue();
      expect(provider.state, SplashState.retry);

      // Tercer intento: éxito
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => true);
      provider.startWaking();
      provider.onAuthResolved();
      await pumpEventQueue();
      expect(provider.state, SplashState.resolved);
    });
  });

  group('auto-auth path', () {
    test(
      'debe funcionar cuando auth ya está resuelto antes de startWaking',
      () async {
        // Arrange: auth ya viene resuelto (escenario ya autenticado)
        provider.onAuthResolved();

        // Act: iniciar el despertar
        provider.startWaking();
        await pumpEventQueue();

        // Assert: va directo a resolved porque auth ya estaba listo
        expect(provider.state, SplashState.resolved);
      },
    );

    test('debe funcionar cuando auth se resuelve durante el wake', () async {
      // Arrange: wakeBackend usa Completer para controlar timing
      final completer = Completer<bool>();
      when(() => mockRepo.wakeBackend()).thenAnswer((_) => completer.future);

      provider.startWaking();

      // Act: auth se resuelve mientras el wake está en vuelo
      provider.onAuthResolved();

      // El timer ya se disparó (Duration.zero), pero wake todavía no
      // Debe quedar en waking hasta que wake se complete
      expect(provider.state, SplashState.waking);

      // Completar el wake
      completer.complete(true);
      await pumpEventQueue();

      // Assert: ahora todas las condiciones están listas
      expect(provider.state, SplashState.resolved);
    });
  });

  group('_onStateChanged callback', () {
    test('debe llamar _onStateChanged en cada transición de estado', () async {
      var onStateChangedCount = 0;
      provider.onStateChanged = () => onStateChangedCount++;

      provider.startWaking();
      provider.onAuthResolved();
      await pumpEventQueue();

      // Debe dispararse en: idle→waking, waking→resolved
      expect(onStateChangedCount, greaterThanOrEqualTo(2));
    });

    test('debe llamar _onStateChanged en transición a retry', () async {
      when(() => mockRepo.wakeBackend()).thenAnswer((_) async => false);

      var onStateChangedCount = 0;
      provider.onStateChanged = () => onStateChangedCount++;

      provider.startWaking();
      await pumpEventQueue();

      // idle→waking, waking→retry
      expect(onStateChangedCount, greaterThanOrEqualTo(2));
    });

    test('_onStateChanged puede ser null sin causar errores', () async {
      // Arrange: onStateChanged no fue seteado (null por defecto)

      // Act & Assert: no debe lanzar excepción
      provider.startWaking();
      provider.onAuthResolved();
      await pumpEventQueue();

      expect(provider.state, SplashState.resolved);
    });
  });

  group('ChangeNotifier', () {
    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });

    test(
      'debe llamar notifyListeners al menos una vez en startWaking',
      () async {
        final completer = Completer<bool>();
        when(() => mockRepo.wakeBackend()).thenAnswer((_) => completer.future);

        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.startWaking();
        expect(notifyCount, greaterThanOrEqualTo(1));

        completer.complete(true);
        await pumpEventQueue();
      },
    );
  });
}
