// Widget de logo MundoLimpio.
//
// Muestra el logo de la app desde `assets/images/logo.png`.
// El asset real se agrega en PR 3 (native assets) — mientras tanto
// el `errorBuilder` muestra un SizedBox coloreado como fallback
// para que la app no crashee si el asset falta.
//
// TDD: GREEN — implementación mínima para pasar el test

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Widget reusable para mostrar el logo de MundoLimpio.
///
/// Carga el logo desde `assets/images/logo.png` usando [Image.asset].
/// Si el asset no está disponible todavía (PR 3), el [errorBuilder]
/// muestra un [SizedBox] del color primario como placeholder seguro.
///
/// ```dart
/// const LogoWidget(size: 80)
/// ```
class LogoWidget extends StatelessWidget {
  /// Tamaño del logo (ancho y alto, mantiene proporción cuadrada).
  ///
  /// Por defecto 120dp.
  final double size;

  const LogoWidget({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo de Mundo Limpio',
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // TODO: reemplazar con el asset real en PR 3 (native assets)
          return SizedBox(
            width: size,
            height: size,
            child: const Icon(
              Icons.eco,
              color: AppColors.primary,
              size: 60,
            ),
          );
        },
      ),
    );
  }
}
