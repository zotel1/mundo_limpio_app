// Pruebas unitarias para ConnectivityService.
// Verifica:
// - isOnline refleja el estado de conectividad
// - notifyListeners se llama en cada cambio de estado
// - online → offline → online transitions
//
// TDD: RED — test escrito antes que la implementación

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';

// Mock de Connectivity de connectivity_plus
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late ConnectivityService service;

  setUp(() {
    mockConnectivity = MockConnectivity();
    connectivityController = StreamController<List<ConnectivityResult>>();

    // Mock: onConnectivityChanged retorna nuestro stream controlado
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);

    // Mock: checkConnectivity retorna conectado por defecto
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
  });

  tearDown(() async {
    await connectivityController.close();
  });

  group('ConnectivityService', () {
    group('inicialización', () {
      test('debe inicializar isOnline como true si hay WiFi', () async {
        service = ConnectivityService(connectivity: mockConnectivity);
        await service.initialize();

        expect(service.isOnline, isTrue);
      });

      test('debe inicializar isOnline como false si no hay conexión', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);
        service = ConnectivityService(connectivity: mockConnectivity);
        await service.initialize();

        expect(service.isOnline, false);
      });
    });

    group('transiciones de estado', () {
      test('debe cambiar isOnline a false cuando la red cae', () async {
        service = ConnectivityService(connectivity: mockConnectivity);
        await service.initialize();

        expect(service.isOnline, isTrue);

        // Simular pérdida de conexión
        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(Duration.zero);

        expect(service.isOnline, false);
      });

      test('debe cambiar isOnline a true cuando la red vuelve', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);
        service = ConnectivityService(connectivity: mockConnectivity);
        await service.initialize();

        expect(service.isOnline, false);

        // Simular reconexión
        connectivityController.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(Duration.zero);

        expect(service.isOnline, true);
      });

      test('debe llamar notifyListeners en cada cambio', () async {
        service = ConnectivityService(connectivity: mockConnectivity);
        await service.initialize();

        var notifyCount = 0;
        service.addListener(() => notifyCount++);

        // Cambio 1: online → offline
        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(Duration.zero);
        expect(notifyCount, 1);

        // Cambio 2: offline → online
        connectivityController.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(Duration.zero);
        expect(notifyCount, 2);
      });

      test('no debe llamar notifyListeners si el estado no cambia', () async {
        service = ConnectivityService(connectivity: mockConnectivity);
        await service.initialize();

        var notifyCount = 0;
        service.addListener(() => notifyCount++);

        // Mismo estado (wifi → wifi)
        connectivityController.add([ConnectivityResult.wifi]);
        await Future<void>.delayed(Duration.zero);
        expect(notifyCount, 0);
      });
    });
  });
}
