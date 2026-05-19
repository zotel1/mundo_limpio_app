// Tema claro de la aplicación MundoLimpio.
//
// Factory estático que construye un [ThemeData] completo a partir
// de los design tokens: [AppColors], [AppTextStyles] y [AppSpacing].
// Usa Material 3 con [ColorScheme.fromSeed] para generar una paleta
// armónica anclada en el navy primario.
//
// TDD: GREEN — implementación mínima para pasar el test

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tema de la aplicación MundoLimpio.
///
/// Provee [ThemeData] para `MaterialApp(theme:)`.
/// Expone un solo getter [light] — la app actualmente solo
/// soporta tema claro. Si en el futuro se agrega dark mode,
/// se agregaría `AppTheme.dark` siguiendo el mismo contrato.
class AppTheme {
  AppTheme._();

  /// Tema claro construido a partir de los design tokens.
  ///
  /// - [ColorScheme] anclado en [AppColors.primary] (navy).
  /// - [TextTheme] poblado desde [AppTextStyles].
  /// - [AppBarTheme] con fondo navy, texto blanco, sin elevación.
  /// - [ElevatedButtonTheme] con fondo navy.
  /// - [ScaffoldBackgroundColor] = [AppColors.background].
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // --- AppBar ---
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // --- Text ---
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.labelLarge,
      ),

      // --- Buttons ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
