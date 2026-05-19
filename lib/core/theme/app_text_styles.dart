// Escala tipográfica de marca MundoLimpio.
//
// Getters `static` que devuelven [TextStyle] con el color navy
// por defecto y sin `fontFamily` (hereda Roboto del sistema).
// Usa getters en vez de `static const` para que cada acceso sea
// independiente — Material 3 muta el [TextStyle] internamente
// al aplicarlo al [TextTheme].
//
// TDD: GREEN — implementación mínima para pasar el test

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografía de marca con las 7 variantes de Material 3.
///
/// Todos los estilos usan [AppColors.primary] (navy #1E2238) como
/// color por defecto y `fontFamily: null` para usar Roboto (system
/// default). La decisión de no usar fuente custom se alinea con
/// el spec — el usuario lo pidió explícitamente.
class AppTextStyles {
  AppTextStyles._();

  /// Display grande — para títulos hero en pantallas principales.
  static TextStyle get displayLarge => const TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
  );

  /// Headline mediano — para títulos de sección.
  static TextStyle get headlineMedium => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
  );

  /// Title grande — para títulos de toolbar y diálogos.
  static TextStyle get titleLarge => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
  );

  /// Title mediano — para subtítulos.
  static TextStyle get titleMedium => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  /// Body grande — para párrafos destacados.
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
  );

  /// Body mediano — texto de lectura principal.
  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
  );

  /// Label grande — para botones y chips.
  static TextStyle get labelLarge => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
}
