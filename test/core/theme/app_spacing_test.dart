// Pruebas unitarias para AppSpacing.
// Verifica que las 5 constantes de espaciado tengan los valores
// canónicos del design system y sean double no nulos.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/core/theme/app_spacing.dart';

void main() {
  group('AppSpacing', () {
    // --- Valores canónicos ---

    test('xs should be 4.0', () {
      expect(AppSpacing.xs, 4.0);
    });

    test('sm should be 8.0', () {
      expect(AppSpacing.sm, 8.0);
    });

    test('md should be 16.0', () {
      // TDD: RED — md = 16 es el valor base del grid de 8dp
      expect(AppSpacing.md, 16.0);
    });

    test('lg should be 24.0', () {
      expect(AppSpacing.lg, 24.0);
    });

    test('xl should be 32.0', () {
      expect(AppSpacing.xl, 32.0);
    });

    // --- No nulabilidad ---

    test('all constants should be non-null', () {
      expect(AppSpacing.xs, isNotNull);
      expect(AppSpacing.sm, isNotNull);
      expect(AppSpacing.md, isNotNull);
      expect(AppSpacing.lg, isNotNull);
      expect(AppSpacing.xl, isNotNull);
    });

    // --- Tipo correcto ---

    test('all constants should be double', () {
      expect(AppSpacing.xs, isA<double>());
      expect(AppSpacing.sm, isA<double>());
      expect(AppSpacing.md, isA<double>());
      expect(AppSpacing.lg, isA<double>());
      expect(AppSpacing.xl, isA<double>());
    });

    // --- Triangulación: relación creciente ---

    test('spacing values should be in increasing order', () {
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
    });

    test('all values should be positive', () {
      expect(AppSpacing.xs, greaterThan(0));
      expect(AppSpacing.sm, greaterThan(0));
      expect(AppSpacing.md, greaterThan(0));
      expect(AppSpacing.lg, greaterThan(0));
      expect(AppSpacing.xl, greaterThan(0));
    });
  });
}
