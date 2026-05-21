// Punto de entrada de la interfaz de la aplicación.
//
// Composition root mínimo: toma los providers inyectados
// desde main.dart y configura MaterialApp.router con GoRouter.
//
// TDD: GREEN — PR3: pasar splashProvider a createRouter

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/provider/auth_provider.dart';
import 'features/splash/presentation/splash_provider.dart';

/// Widget raíz de la aplicación.
///
/// Usa [MaterialApp.router] con GoRouter para manejo de rutas
/// y redirecciones basadas en autenticación y estado del splash.
///
/// Los providers (TokenStorage, AuthRepository, AuthProvider,
/// SplashRepository, SplashProvider) se inyectan desde [main]
/// via MultiProvider.
class MundoLimpioApp extends StatelessWidget {
  const MundoLimpioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener los providers para pasarlos al router
    final authProvider = context.read<AuthProvider>();
    final splashProvider = context.read<SplashProvider>();

    return MaterialApp.router(
      title: 'MundoLimpio',
      routerConfig: createRouter(authProvider, splashProvider),
      // TDD: GREEN — reemplazar ThemeData inline por AppTheme.light
      theme: AppTheme.light,
    );
  }
}
