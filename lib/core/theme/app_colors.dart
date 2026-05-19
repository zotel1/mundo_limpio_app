// Paleta de colores de marca MundoLimpio.
//
// Constantes `static const` para que el compilador garantice
// valores en tiempo de compilación — sin allocaciones en runtime,
// ideales para el árbol de widgets de Flutter.
//
// TDD: GREEN — implementación mínima para pasar el test de AppColors

import 'package:flutter/material.dart';

/// Constantes de color de la identidad visual MundoLimpio.
///
/// Todos los colores son [static const] para uso directo en
/// constructores `const` y [ThemeData].
///
/// La paleta sigue la guía de marca:
/// - [primary]: azul marino del logo (#1E2238)
/// - [secondary]: verde oscuro complementario (#2E7D32)
/// - [tertiary]: cyan claro para acentos (#4FC3F7)
/// - [surface]: blanco puro para superficies (#FFFFFF)
/// - [background]: gris muy claro para fondos (#F5F5F5)
/// - [error]: rojo Material 700 para estados de error (#D32F2F)
/// - [accent]: gris azulado medio del logo (#9FA2B5)
class AppColors {
  const AppColors._();

  /// Azul marino del logo MundoLimpio.
  static const Color primary = Color(0xFF1E2238);

  /// Verde oscuro — color secundario de la marca.
  static const Color secondary = Color(0xFF2E7D32);

  /// Cyan claro — color terciario para acentos y destacados.
  static const Color tertiary = Color(0xFF4FC3F7);

  /// Blanco puro para superficies de tarjetas y diálogos.
  static const Color surface = Color(0xFFFFFFFF);

  /// Gris muy claro para el fondo de pantalla.
  static const Color background = Color(0xFFF5F5F5);

  /// Rojo Material 700 — indica error o estado destructivo.
  static const Color error = Color(0xFFD32F2F);

  /// Gris azulado medio del degradado del logo.
  static const Color accent = Color(0xFF9FA2B5);
}
