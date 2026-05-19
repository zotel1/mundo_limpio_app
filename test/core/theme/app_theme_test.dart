// Pruebas unitarias para AppTheme.light.
// Verifica que el ThemeData se construya correctamente a partir
// de los design tokens (AppColors + AppTextStyles) y cumpla con
// los requerimientos de Material 3.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/core/theme/app_colors.dart';
import 'package:mundo_limpio_app/core/theme/app_text_styles.dart';
import 'package:mundo_limpio_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme.light', () {
    // --- Color Scheme ---

    test('colorScheme.primary should match AppColors.primary', () {
      // TDD: RED — la fuente de verdad del color primario es AppColors
      expect(AppTheme.light.colorScheme.primary, AppColors.primary);
    });

    test('colorScheme.secondary should match AppColors.secondary', () {
      expect(AppTheme.light.colorScheme.secondary, AppColors.secondary);
    });

    test('colorScheme.surface should match AppColors.surface', () {
      expect(AppTheme.light.colorScheme.surface, AppColors.surface);
    });

    test('colorScheme.error should match AppColors.error', () {
      expect(AppTheme.light.colorScheme.error, AppColors.error);
    });

    // --- Material 3 ---

    test('should use Material 3', () {
      // TDD: RED — Material 3 es requerido por el spec
      expect(AppTheme.light.useMaterial3, isTrue);
    });

    // --- Scaffold background ---

    test('scaffoldBackgroundColor should match AppColors.background', () {
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.background);
    });

    // --- AppBar Theme ---

    test('appBarTheme should have navy background', () {
      expect(AppTheme.light.appBarTheme.backgroundColor, AppColors.primary);
    });

    test('appBarTheme should have white foreground', () {
      expect(AppTheme.light.appBarTheme.foregroundColor, Colors.white);
    });

    test('appBarTheme should have elevation 0', () {
      expect(AppTheme.light.appBarTheme.elevation, 0);
    });

    // --- Text Theme ---

    test('textTheme.bodyMedium should match AppTextStyles.bodyMedium', () {
      // La fuente de verdad de la tipografía es AppTextStyles
      expect(
        AppTheme.light.textTheme.bodyMedium?.color,
        AppTextStyles.bodyMedium.color,
      );
      expect(
        AppTheme.light.textTheme.bodyMedium?.fontSize,
        AppTextStyles.bodyMedium.fontSize,
      );
    });

    test('textTheme should have all 7 variants non-null', () {
      final textTheme = AppTheme.light.textTheme;
      expect(textTheme.displayLarge, isNotNull);
      expect(textTheme.headlineMedium, isNotNull);
      expect(textTheme.titleLarge, isNotNull);
      expect(textTheme.titleMedium, isNotNull);
      expect(textTheme.bodyLarge, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.labelLarge, isNotNull);
    });

    // --- Elevated Button Theme ---

    test('elevatedButtonTheme should have navy background', () {
      final buttonStyle = AppTheme.light.elevatedButtonTheme.style;
      expect(buttonStyle, isNotNull);
      // Resolve background color with no interaction state
      final resolved = buttonStyle?.backgroundColor?.resolve({});
      expect(resolved, AppColors.primary);
    });

    // --- Triangulación: theme is not null and is ThemeData ---

    test('theme should be non-null ThemeData', () {
      expect(AppTheme.light, isNotNull);
      expect(AppTheme.light, isA<ThemeData>());
    });
  });
}
