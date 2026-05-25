// Pantalla de splash interactiva con la mascota del gato.
//
// Implementa la UI del splash screen que reacciona al estado
// del SplashProvider:
// - idle: gato durmiendo con prompt "Tocá para despertar al gato..."
// - waking: gato despertando (sin texto, la imagen es el indicador)
// - retry: mensaje de error + botón de reintentar
// - resolved: navega imperativamente via context.go()
//
// También observa AuthProvider y notifica al SplashProvider
// cuando la autenticación se resuelve (status != loading).
//
// TDD: GREEN — splash-auth-flow: navegación imperativa post-resolución

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/theme/app_colors.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/splash/domain/splash_state.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_provider.dart';

/// Pantalla de splash interactiva con el gato mascota.
///
/// Observa [SplashProvider] para reaccionar a cambios de estado
/// y [AuthProvider] para notificar cuando la autenticación se resuelve.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _authNotified = false;
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final splash = context.watch<SplashProvider>();
    final auth = context.watch<AuthProvider>();

    // Notificar al splash provider cuando la autenticación se resuelve.
    // Solo se llama una vez para evitar bucles infinitos de rebuild.
    if (!_authNotified && auth.status != AuthStatus.loading) {
      _authNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        splash.onAuthResolved();
      });
    }

    // Navegación imperativa cuando el splash se resuelve.
    // Se ejecuta una sola vez gracias al flag _navigated.
    if (!_navigated && splash.state == SplashState.resolved) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (auth.isAuthenticated) {
          context.go('/');
        } else {
          context.go('/login');
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: GestureDetector(
        onTap: splash.state == SplashState.idle ? splash.startWaking : null,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _imageForState(splash.state),
                width: 200,
                height: 200,
              ),
              if (splash.state == SplashState.idle) ...[
                const SizedBox(height: 24),
                const Text(
                  'Tocá para despertar al gato...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
              if (splash.state == SplashState.retry) ...[
                const SizedBox(height: 24),
                const Text(
                  'No se pudo conectar con el servidor',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: splash.startWaking,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Retorna el asset de imagen correspondiente al estado del splash.
  String _imageForState(SplashState state) {
    switch (state) {
      case SplashState.idle:
        return 'assets/images/02_cat_sleeping.png';
      case SplashState.waking:
        return 'assets/images/04_cat_waking.png';
      case SplashState.retry:
        return 'assets/images/02_cat_sleeping.png';
      case SplashState.resolved:
        return 'assets/images/02_cat_sleeping.png'; // No debería renderizarse
    }
  }
}
