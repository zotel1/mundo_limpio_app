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
import 'package:go_router/go_router.dart';
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Bienvenido! Sesión iniciada correctamente.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            // Botón "Nueva Venta" solo para administradores (T-5.3)
            if (context.read<AuthProvider>().role == 'ADMIN') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/sales/new'),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Nueva Venta'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/inventory'),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Inventario'),
                ),
              ),
            ],
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
