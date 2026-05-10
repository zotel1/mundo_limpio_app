// Configuración del router de la aplicación.
//
// Define las rutas de la app y la lógica de redirect
// basada en el estado de autenticación (AuthStatus).
//
// Usa GoRouter con refreshListenable para que los redirects
// se reevalúen automáticamente cuando AuthProvider notifica
// cambios en el estado de autenticación.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/register_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/home_screen.dart';

// ---------------------------------------------------------------------------
// Pantalla de splash / carga
// ---------------------------------------------------------------------------

/// Pantalla que se muestra mientras se resuelve el estado de auth.
///
/// Aparece durante el startup cuando AuthStatus es loading.
/// Tan pronto como el estado cambia a authenticated o unauthenticated,
/// el redirect de GoRouter redirige a la ruta correspondiente.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fábrica del router
// ---------------------------------------------------------------------------

/// Crea un [GoRouter] que protege rutas según [authProvider].
///
/// [authProvider] se usa para:
/// 1. Leer el estado actual via [AuthProvider.status]
/// 2. Notificar cambios via [ChangeNotifier] (refreshListenable)
///
/// [initialLocation] permite arrancar desde una ruta específica
/// (por defecto: '/').
///
/// Lógica de redirect:
/// - loading → redirige a /splash si no está ahí
/// - unauthenticated → /login y /register libres; el resto redirige a /login
/// - authenticated → /login, /register y /splash redirigen a /
GoRouter createRouter(
  AuthProvider authProvider, {
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final location = state.matchedLocation;

      switch (status) {
        case AuthStatus.loading:
          // Mostrar splash mientras se resuelve el estado
          if (location != '/splash') return '/splash';
          return null;

        case AuthStatus.unauthenticated:
          // Solo login y register son accesibles (R6.1)
          if (location == '/login' || location == '/register') return null;
          return '/login';

        case AuthStatus.authenticated:
          // Redirigir al home si está en pantallas de auth (R6.2)
          if (location == '/login' ||
              location == '/register' ||
              location == '/splash') {
            return '/';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  );
}
