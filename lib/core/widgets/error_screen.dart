// Pantalla de error para errores de parseo y excepciones.
//
// Se muestra cuando GoRouter encuentra un FormatException (parámetros
// no numéricos) u otras excepciones durante la navegación.
// También se usa para rutas con state.extra nulo (B3).
//
// TDD: GREEN — implementación mínima para pasar error_screen_test
// TDD: GREEN (B3) — parámetros message, backLabel, onBackPressed para null-extra

import 'package:flutter/material.dart';

import 'package:mundo_limpio_app/core/widgets/not_found_screen.dart';

/// Pantalla mostrada cuando ocurre un error de navegación.
///
/// Para [FormatException] muestra un icono de error y el mensaje.
/// Para [error] null muestra [NotFoundScreen].
///
/// Parámetros opcionales para null-extra (B3):
/// - [message]: mensaje de error personalizado (reemplaza [error].toString())
/// - [backLabel]: texto del botón de navegación (default: 'Volver al inicio')
/// - [onBackPressed]: callback al presionar el botón (default: pop al inicio)
class ErrorScreen extends StatelessWidget {
  final Object? error;
  final String? message;
  final String? backLabel;
  final VoidCallback? onBackPressed;

  const ErrorScreen({
    super.key,
    this.error,
    this.message,
    this.backLabel,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Solo muestra NotFoundScreen cuando NO hay message ni error
    if (error == null && message == null) return const NotFoundScreen();

    final displayMessage = message ?? error.toString();

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
                message != null ? 'Error' : 'Algo salió mal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed:
                    onBackPressed ??
                    () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                icon: onBackPressed != null
                    ? const Icon(Icons.arrow_back)
                    : const Icon(Icons.home),
                label: Text(backLabel ?? 'Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
