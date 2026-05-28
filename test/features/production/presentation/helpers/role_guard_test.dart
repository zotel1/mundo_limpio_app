// TDD: RED — test escrito antes que la implementación
//
// Pruebas unitarias para RoleGuard.hasAnyRole.
//
// Verifica que:
// - roles null → false
// - lista vacía → false
// - match exacto → true
// - match parcial (anyOf) → true
// - sin match → false

import 'package:flutter_test/flutter_test.dart';
import 'package:mundo_limpio_app/core/helpers/role_guard.dart';

void main() {
  group('RoleGuard.hasAnyRole', () {
    test('debe retornar false cuando roles es null', () {
      expect(RoleGuard.hasAnyRole(null, ['ADMIN']), isFalse);
    });

    test('debe retornar false cuando roles está vacío', () {
      expect(RoleGuard.hasAnyRole([], ['ADMIN']), isFalse);
    });

    test('debe retornar true cuando hay match exacto', () {
      expect(RoleGuard.hasAnyRole(['ADMIN'], ['ADMIN']), isTrue);
    });

    test('debe retornar true cuando hay match parcial (anyOf)', () {
      expect(
        RoleGuard.hasAnyRole(['CUSTOMER'], ['ADMIN', 'STOCK_MANAGER']),
        isFalse,
      );
      expect(
        RoleGuard.hasAnyRole(['ADMIN'], ['ADMIN', 'STOCK_MANAGER']),
        isTrue,
      );
      expect(
        RoleGuard.hasAnyRole(['STOCK_MANAGER'], ['ADMIN', 'STOCK_MANAGER']),
        isTrue,
      );
    });

    test('debe retornar false cuando no hay match', () {
      expect(RoleGuard.hasAnyRole(['CUSTOMER'], ['ADMIN']), isFalse);
    });
  });
}
