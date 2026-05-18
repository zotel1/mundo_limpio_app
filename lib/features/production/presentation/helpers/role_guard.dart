// Widget de guardia que restringe el acceso a usuarios según su rol.
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// RoleGuard envuelve un child widget y solo lo muestra cuando
// el rol del usuario autenticado coincide con requiredRole.
// Si no coincide, muestra AccessDeniedScreen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';

/// Pantalla simple de acceso denegado.
///
/// Se muestra cuando el usuario no tiene el rol requerido.
class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Access Denied'),
      ),
    );
  }
}

/// Widget wrapper que condiciona la visibilidad del [child] al rol del usuario.
///
/// Lee [AuthProvider] del contexto y compara [authProvider.role]
/// con [requiredRole]. Si coinciden, muestra el [child].
/// Caso contrario, muestra [AccessDeniedScreen].
class RoleGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole;

  const RoleGuard({
    super.key,
    required this.child,
    required this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.role == requiredRole) {
      return child;
    }
    return const AccessDeniedScreen();
  }
}
