// Servicio de monitoreo de conectividad de red.
//
// Wrapper sobre connectivity_plus que expone el estado online/offline
// como un ChangeNotifier para que los repositories y la UI reaccionen
// a cambios de conectividad sin depender directamente del paquete.
//
// TDD: GREEN — implementación mínima para pasar connectivity_service_test.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitorea el estado de conectividad y notifica cambios a los listeners.
///
/// Uso:
/// ```dart
/// final service = ConnectivityService();
/// await service.initialize(); // escucha el stream de connectivity_plus
/// service.addListener(() => print('Online: ${service.isOnline}'));
/// ```
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// [connectivity] es inyectable para facilitar tests con mocks.
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Estado actual de conectividad.
  bool get isOnline => _isOnline;

  /// Inicializa el servicio: consulta el estado inicial y comienza
  /// a escuchar cambios en la conectividad.
  Future<void> initialize() async {
    // Estado inicial
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    // Escuchar cambios
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final online = !results.contains(ConnectivityResult.none);
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
