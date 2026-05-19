// Punto de entrada de la interfaz de la aplicación.
//
// Composition root mínimo: toma los providers inyectados
// desde main.dart y configura MaterialApp.router con GoRouter.
//
// TDD: GREEN — implementación mínima de la app shell

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/provider/auth_provider.dart';

/// Widget raíz de la aplicación.
///
/// Usa [MaterialApp.router] con GoRouter para manejo de rutas
/// y redirecciones basadas en autenticación.
///
/// Los providers (TokenStorage, AuthRepository, AuthProvider)
/// se inyectan desde [main] via MultiProvider.
class MundoLimpioApp extends StatelessWidget {
  const MundoLimpioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el provider de auth para pasarlo al router
    final authProvider = context.read<AuthProvider>();

    return MaterialApp.router(
      title: 'MundoLimpio',
      routerConfig: createRouter(authProvider),
      // TDD: GREEN — reemplazar ThemeData inline por AppTheme.light
      theme: AppTheme.light,
    );
  }
}
