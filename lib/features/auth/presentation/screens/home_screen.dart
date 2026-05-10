// Pantalla principal post-login.
//
// Muestra un mensaje de bienvenida y un botón de cerrar sesión
// con confirmación. Después del logout navega a LoginScreen.
//
// Estados:
// - AUTHENTICATED: muestra bienvenida + botón logout
// - LOGOUT CONFIRMATION: diálogo de confirmación
// - POST-LOGOUT: navegación a LoginScreen
//
// TDD: GREEN — creado después de que AuthProvider pasa los tests

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import 'login_screen.dart';

/// Pantalla de inicio después de autenticación exitosa.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MundoLimpio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              '¡Bienvenido! Sesión iniciada correctamente.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra diálogo de confirmación antes de cerrar sesión.
  void _showLogoutDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que querés cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        // Limpiar sesión y redirigir al login
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    });
  }
}
