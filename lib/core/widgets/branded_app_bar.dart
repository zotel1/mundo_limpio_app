// AppBar de marca MundoLimpio.
//
// Reemplazo directo de `AppBar` con los tokens visuales consistentes:
// - Fondo navy (AppColors.primary)
// - Título blanco en titleLarge
// - Elevación 0 (flat, Material moderno)
// - Actions heredan foregroundColor blanco
//
// TDD: GREEN — implementación mínima para pasar el test

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// AppBar estandarizado para toda la app MundoLimpio.
///
/// Construye un [AppBar] interno con los tokens de marca.
/// Implementa [PreferredSizeWidget] para integración directa en [Scaffold].
///
/// ```dart
/// Scaffold(
///   appBar: BrandedAppBar(title: 'Login'),
///   body: ...
/// )
/// ```
class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Título visible en el AppBar.
  final String title;

  /// Acciones opcionales (iconos, botones) alineados a la derecha.
  final List<Widget>? actions;

  /// Si debe mostrar automáticamente la flecha de back cuando
  /// hay una ruta anterior en el stack de navegación.
  ///
  /// Por defecto `true`.
  final bool automaticallyImplyLeading;

  const BrandedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(
        title,
        style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
      ),
      actions: actions,
    );
  }
}
