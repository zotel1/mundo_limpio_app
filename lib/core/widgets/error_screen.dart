// Pantalla de error para errores de parseo y excepciones.
//
// Se muestra cuando GoRouter encuentra un FormatException (parámetros
// no numéricos) u otras excepciones durante la navegación.
//
// TDD: GREEN — implementación mínima para pasar error_screen_test

import 'package:flutter/material.dart';

import 'package:mundo_limpio_app/core/widgets/not_found_screen.dart';

/// Pantalla mostrada cuando ocurre un error de navegación.
///
/// Para [FormatException] muestra un icono de error y el mensaje.
/// Para [error] null muestra [NotFoundScreen].
class ErrorScreen extends StatelessWidget {
  final Object? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const NotFoundScreen();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Algo salió mal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
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
