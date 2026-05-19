// Banner de error estandarizado para la app MundoLimpio.
//
// Muestra un mensaje de error con estilos de marca:
// - Fondo surface (blanco)
// - Icono en color error (rojo de marca)
// - Texto descriptivo del error
// - Botón de cierre opcional (onDismiss)
// - Accesible vía Semantics
//
// TDD: GREEN — implementación mínima para pasar el test

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Banner de error reusable con los tokens de marca.
///
/// Útil para mostrar errores inline en pantallas como login,
/// register, formularios, o cualquier flujo donde un error
/// deba mostrarse de forma consistente.
///
/// ```dart
/// BrandedErrorBanner(
///   message: 'Error de conexión',
///   onDismiss: () => setState(() => _error = null),
/// )
/// ```
class BrandedErrorBanner extends StatelessWidget {
  /// Mensaje descriptivo del error.
  final String message;

  /// Callback opcional que se dispara al tocar el botón X de cierre.
  ///
  /// Si es `null`, el botón de cierre no se renderiza.
  final VoidCallback? onDismiss;

  const BrandedErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Error: $message',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(left: BorderSide(color: AppColors.error, width: 4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
                color: AppColors.accent,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
