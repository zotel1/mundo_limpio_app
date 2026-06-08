// Pantalla de error para rutas no encontradas (404).
//
// Se muestra cuando GoRouter no encuentra una ruta que coincida
// con la URL solicitada, o cuando hay un error en los parámetros
// de la ruta.
//
// TDD: GREEN — implementación mínima para el errorBuilder del router

import 'package:flutter/material.dart';

/// Pantalla mostrada cuando una ruta no es encontrada.
///
/// Reemplaza el error genérico de Flutter por una experiencia
/// controlada con navegación de retorno al inicio.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                'Página no encontrada',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'La página que buscas no existe o el enlace no es válido.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home),
                label: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
