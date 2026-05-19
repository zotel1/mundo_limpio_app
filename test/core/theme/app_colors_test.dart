// Pruebas unitarias para AppColors.
// Verifica que la paleta de colores de marca contenga todos los
// constantes con los valores exactos definidos en el spec.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    // --- Valor exacto de cada color ---

    test('primary should be navy #1E2238', () {
      // TDD: RED — el spec exige primary como el azul marino del logo
      expect(AppColors.primary, const Color(0xFF1E2238));
    });

    test('secondary should be dark green #2E7D32', () {
      expect(AppColors.secondary, const Color(0xFF2E7D32));
    });

    test('tertiary should be light cyan #4FC3F7', () {
      expect(AppColors.tertiary, const Color(0xFF4FC3F7));
    });

    test('surface should be white #FFFFFF', () {
      expect(AppColors.surface, const Color(0xFFFFFFFF));
    });

    test('background should be off-white #F5F5F5', () {
      expect(AppColors.background, const Color(0xFFF5F5F5));
    });

    test('error should be Material red 700 #D32F2F', () {
      expect(AppColors.error, const Color(0xFFD32F2F));
    });

    test('accent should be blue-gray #9FA2B5', () {
      expect(AppColors.accent, const Color(0xFF9FA2B5));
    });

    // --- Integridad de la paleta ---

    test('all constants should be non-null', () {
      // TDD: RED — cada constante debe ser dereferenceable sin NPE
      expect(AppColors.primary, isNotNull);
      expect(AppColors.secondary, isNotNull);
      expect(AppColors.tertiary, isNotNull);
      expect(AppColors.surface, isNotNull);
      expect(AppColors.background, isNotNull);
      expect(AppColors.error, isNotNull);
      expect(AppColors.accent, isNotNull);
    });

    test('all constants should have distinct values', () {
      // TDD: TRIANGULATE — cada color cumple un rol distinto;
      // sin duplicados accidentales
      final all = <Color>[
        AppColors.primary,
        AppColors.secondary,
        AppColors.tertiary,
        AppColors.surface,
        AppColors.background,
        AppColors.error,
        AppColors.accent,
      ];
      expect(all.toSet().length, all.length);
    });

    test('constants should be compile-time const', () {
      // TDD: TRIANGULATE — las constantes deben ser `const` para
      // evitar allocaciones en runtime
      const _ = AppColors.primary;
      const _ = AppColors.secondary;
      const _ = AppColors.tertiary;
      const _ = AppColors.surface;
      const _ = AppColors.background;
      const _ = AppColors.error;
      const _ = AppColors.accent;
      // Si compila, el test pasa — ningún `expect` necesario.
      expect(true, isTrue); // garantiza que el test no quede vacío
    });
  });
}
