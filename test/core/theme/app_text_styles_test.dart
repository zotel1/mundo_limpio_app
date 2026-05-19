// Pruebas unitarias para AppTextStyles.
// Verifica que la escala tipográfica tenga el color navy por defecto,
// fontFamily nulo (system default Roboto), y las 7 variantes accesibles.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/core/theme/app_text_styles.dart';

void main() {
  group('AppTextStyles', () {
    // --- Color por defecto ---

    test('bodyMedium should default to navy color', () {
      // TDD: RED — el spec requiere que el color por defecto
      // de todo estilo sea el navy primario
      expect(AppTextStyles.bodyMedium.color, const Color(0xFF1E2238));
    });

    test('all text styles should default to navy color', () {
      // TDD: TRIANGULATE — todas las variantes heredan navy
      final styles = <TextStyle>[
        AppTextStyles.displayLarge,
        AppTextStyles.headlineMedium,
        AppTextStyles.titleLarge,
        AppTextStyles.titleMedium,
        AppTextStyles.bodyLarge,
        AppTextStyles.bodyMedium,
        AppTextStyles.labelLarge,
      ];
      for (final style in styles) {
        expect(style.color, const Color(0xFF1E2238));
      }
    });

    // --- Font family ---

    test('fontFamily should be null on all styles', () {
      // El spec es explícito: sin fuente custom (Roboto system default)
      final styles = <TextStyle>[
        AppTextStyles.displayLarge,
        AppTextStyles.headlineMedium,
        AppTextStyles.titleLarge,
        AppTextStyles.titleMedium,
        AppTextStyles.bodyLarge,
        AppTextStyles.bodyMedium,
        AppTextStyles.labelLarge,
      ];
      for (final style in styles) {
        expect(style.fontFamily, isNull);
      }
    });

    // --- Accesibilidad de las 7 variantes ---

    test('displayLarge should be non-null and a TextStyle', () {
      expect(AppTextStyles.displayLarge, isA<TextStyle>());
      expect(AppTextStyles.displayLarge, isNotNull);
    });

    test('headlineMedium should be non-null and a TextStyle', () {
      expect(AppTextStyles.headlineMedium, isA<TextStyle>());
      expect(AppTextStyles.headlineMedium, isNotNull);
    });

    test('titleLarge should be non-null and a TextStyle', () {
      expect(AppTextStyles.titleLarge, isA<TextStyle>());
      expect(AppTextStyles.titleLarge, isNotNull);
    });

    test('titleMedium should be non-null and a TextStyle', () {
      expect(AppTextStyles.titleMedium, isA<TextStyle>());
      expect(AppTextStyles.titleMedium, isNotNull);
    });

    test('bodyLarge should be non-null and a TextStyle', () {
      expect(AppTextStyles.bodyLarge, isA<TextStyle>());
      expect(AppTextStyles.bodyLarge, isNotNull);
    });

    test('bodyMedium should be non-null and a TextStyle', () {
      expect(AppTextStyles.bodyMedium, isA<TextStyle>());
      expect(AppTextStyles.bodyMedium, isNotNull);
    });

    test('labelLarge should be non-null and a TextStyle', () {
      expect(AppTextStyles.labelLarge, isA<TextStyle>());
      expect(AppTextStyles.labelLarge, isNotNull);
    });

    // --- Triangulación: estilos tienen tamaños crecientes razonables ---

    test('displayLarge should be larger than bodyMedium', () {
      final display = AppTextStyles.displayLarge.fontSize;
      final body = AppTextStyles.bodyMedium.fontSize;
      expect(display, isNotNull);
      expect(body, isNotNull);
      expect(display!, greaterThan(body!));
    });

    test('headlineMedium should be larger than bodyMedium', () {
      final headline = AppTextStyles.headlineMedium.fontSize;
      final body = AppTextStyles.bodyMedium.fontSize;
      expect(headline, isNotNull);
      expect(body, isNotNull);
      expect(headline!, greaterThan(body!));
    });
  });
}
