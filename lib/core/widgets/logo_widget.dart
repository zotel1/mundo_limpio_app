// Widget de logo MundoLimpio.
//
// Muestra el logo de la app: el gato limpiando (08_cat_cleaning_logo.png).
// Si el asset no está disponible, el errorBuilder muestra un Icon de
// fallback para que la app no crashee.
//
// TDD: GREEN — actualizar path al nuevo logo del gato

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Widget reusable para mostrar el logo de MundoLimpio.
///
/// Carga el logo desde `assets/images/08_cat_cleaning_logo.png`
/// usando [Image.asset]. Si el asset falla en runtime, el
/// [errorBuilder] muestra un [Icon] de fallback.
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
        'assets/images/08_cat_cleaning_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: size,
            height: size,
            child: const Icon(Icons.eco, color: AppColors.primary, size: 60),
          );
        },
      ),
    );
  }
}
