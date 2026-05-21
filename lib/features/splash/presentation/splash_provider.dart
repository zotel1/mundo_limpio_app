// Proveedor de estado del splash screen interactivo.
//
// Implementa la máquina de estados idle→waking→retry→resolved
// que coordina tres condiciones asíncronas en paralelo:
// 1. Animación visual (timer de 2 segundos mínimos)
// 2. Llamada de salud al backend (wakeBackend)
// 3. Resolución de autenticación (onAuthResolved)
//
// Expone un callback _onStateChanged para que GoRouter pueda
// re-evaluar sus redirects cuando el estado cambia.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/splash_repository.dart';
import '../domain/splash_state.dart';

/// ChangeNotifier que gestiona el ciclo de vida del splash screen.
///
/// El [animationDuration] es inyectable para permitir testing
/// con Duration.zero. En producción usa 2 segundos por defecto.
class SplashProvider extends ChangeNotifier {
  final SplashRepository _repository;
  final Duration _animationDuration;

  SplashState _state = SplashState.idle;
  DateTime? _animationStart;
  bool _wakeOk = false;
  bool _wakeCompleted = false; // Si la llamada al backend ya terminó
  bool _authResolved = false;

  /// Callback que se invoca en cada transición de estado.
  ///
  /// GoRouter lo usa para re-evaluar redirects sin necesidad
  /// de que el provider conozca al router directamente.
  void Function()? onStateChanged;

  /// Crea el provider con el repositorio de splash inyectado.
  ///
  /// [animationDuration] controla el tiempo mínimo que debe durar
  /// la animación. En producción es 2 segundos, en tests es cero.
  SplashProvider(
    this._repository, {
    Duration animationDuration = const Duration(seconds: 2),
  }) : _animationDuration = animationDuration;

  /// Estado actual de la máquina de estados.
  SplashState get state => _state;

  /// Si el splash está en estado inicial (gato durmiendo).
  bool get isIdle => _state == SplashState.idle;

  /// Si el splash está ejecutando la secuencia de despertar.
  bool get isWaking => _state == SplashState.waking;

  /// Si el backend no respondió y se debe mostrar reintentar.
  bool get isRetry => _state == SplashState.retry;

  /// Si todas las condiciones se cumplieron, listo para navegar.
  bool get isResolved => _state == SplashState.resolved;

  /// Inicia la secuencia de despertar.
  ///
  /// Transiciona a [SplashState.waking] y dispara en paralelo:
  /// - Un timer que espera [animationDuration] segundos
  /// - Una llamada a [_repository.wakeBackend]
  ///
  /// Puede llamarse desde idle (tap del usuario) o desde retry
  /// (botón de reintentar). En ambos casos reinicia las condiciones.
  void startWaking() {
    _state = SplashState.waking;
    _animationStart = DateTime.now();
    _wakeOk = false; // Reiniciar para reintentos
    _wakeCompleted = false; // Reiniciar flag de completitud
    notifyListeners();
    onStateChanged?.call();

    // Timer: garantiza que la animación dure al menos animationDuration
    Timer(_animationDuration, _checkResolved);

    // Wake call: verifica salud del backend en paralelo
    _callWakeBackend();
  }

  /// Envuelve la llamada a wakeBackend para manejar tanto
  /// excepciones síncronas como futuros con error.
  void _callWakeBackend() {
    try {
      _repository
          .wakeBackend()
          .then((ok) {
            _wakeOk = ok;
            _wakeCompleted = true;
            _checkResolved();
          })
          .catchError((_) {
            // El futuro se completó con error
            _wakeOk = false;
            _wakeCompleted = true;
            _checkResolved();
          });
    } catch (_) {
      // La llamada lanzó síncronamente (raro, pero mocktail puede)
      _wakeOk = false;
      _wakeCompleted = true;
      _checkResolved();
    }
  }

  /// Notifica que la autenticación se resolvió.
  ///
  /// Lo llama el SplashScreen cuando [AuthProvider.status] deja
  /// de ser [AuthStatus.loading]. Puede llamarse antes, durante
  /// o después de [startWaking] — el provider maneja cualquier orden.
  void onAuthResolved() {
    _authResolved = true;
    _checkResolved();
  }

  /// Evalúa si todas las condiciones están listas para navegar.
  ///
  /// Se dispara por eventos (timer, wake result, auth resolved)
  /// en lugar de polling. Solo cuando las tres condiciones se
  /// cumplen simultáneamente transiciona a [SplashState.resolved].
  ///
  /// Si el backend falló y la animación terminó, transiciona a
  /// [SplashState.retry] para que el usuario pueda reintentar.
  void _checkResolved() {
    final animationDone =
        _animationStart != null &&
        DateTime.now().difference(_animationStart!) >= _animationDuration;

    if (animationDone && _wakeOk && _authResolved) {
      _state = SplashState.resolved;
      notifyListeners();
      onStateChanged?.call();
    } else if (!_wakeOk && _wakeCompleted && animationDone) {
      _state = SplashState.retry;
      notifyListeners();
      onStateChanged?.call();
    }
  }
}
