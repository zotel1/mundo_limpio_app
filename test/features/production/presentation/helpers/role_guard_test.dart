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

  group('RoleGuard.isRouteAllowed', () {
    /// Mapa de rutas simplificado (mismo que en app_router.dart).
    final routeMap = <String, Set<String>>{
      '/users': {'ADMIN'},
      '/products/new': {'ADMIN'},
      '/production/': {'ADMIN', 'PRODUCTION_OP'},
      '/receipts/': {'ADMIN', 'STOCK_MANAGER', 'STOCK_OPERATOR'},
      '/sales/new': {'ADMIN', 'SALES_CLERK'},
      '/inventory': {'ADMIN', 'STOCK_MANAGER'},
      '/products': {
        'ADMIN',
        'STOCK_MANAGER',
        'STOCK_OPERATOR',
        'SALES_CLERK',
        'PRODUCTION_OP',
        'ACCOUNTANT',
        'CUSTOMER',
      },
    };

    /// Test parametrizado: 7 roles × rutas clave.
    ///
    /// Formato: (roles, path, esperado)
    /// - true: el rol puede acceder a la ruta
    /// - false: el rol NO puede acceder (ruta restringida)
    /// - null: el rol no se evalúa para esta ruta (se salta por claridad)
    ({List<String> roles, String path, bool? expected}) Function() t(
      String role,
      String path,
      bool? expected,
    ) {
      return () => (roles: [role], path: path, expected: expected);
    }

    final cases = [
      // ADMIN
      t('ADMIN', '/users', true),
      t('ADMIN', '/products/new', true),
      t('ADMIN', '/production/batches', true),
      t('ADMIN', '/receipts/new', true),
      t('ADMIN', '/sales/new', true),
      t('ADMIN', '/inventory', true),
      t('ADMIN', '/products', true),
      // STOCK_MANAGER
      t('STOCK_MANAGER', '/users', false),
      t('STOCK_MANAGER', '/products/new', false),
      t('STOCK_MANAGER', '/production/batches', false),
      t('STOCK_MANAGER', '/receipts/new', true),
      t('STOCK_MANAGER', '/sales/new', false),
      t('STOCK_MANAGER', '/inventory', true),
      t('STOCK_MANAGER', '/products', true),
      // STOCK_OPERATOR
      t('STOCK_OPERATOR', '/production/batches', false),
      t('STOCK_OPERATOR', '/receipts/new', true),
      t('STOCK_OPERATOR', '/sales/new', false),
      t('STOCK_OPERATOR', '/products', true),
      // SALES_CLERK
      t('SALES_CLERK', '/sales/new', true),
      t('SALES_CLERK', '/production/batches', false),
      t('SALES_CLERK', '/products', true),
      // PRODUCTION_OP
      t('PRODUCTION_OP', '/production/batches', true),
      t('PRODUCTION_OP', '/products', true),
      t('PRODUCTION_OP', '/receipts/new', false),
      // ACCOUNTANT
      t('ACCOUNTANT', '/products', true),
      t('ACCOUNTANT', '/users', false),
      t('ACCOUNTANT', '/inventory', false),
      // CUSTOMER
      t('CUSTOMER', '/products', true),
      t('CUSTOMER', '/users', false),
      t('CUSTOMER', '/sales/new', false),
    ];

    for (final c in cases) {
      final data = c();
      final label = data.expected == true
          ? '${data.roles.first} PUEDE acceder a ${data.path}'
          : '${data.roles.first} NO PUEDE acceder a ${data.path}';

      test(label, () {
        expect(
          RoleGuard.isRouteAllowed(data.roles, data.path, routeMap),
          equals(data.expected),
        );
      });
    }

    test('debe retornar true para rutas no mapeadas (públicas)', () {
      expect(
        RoleGuard.isRouteAllowed(['CUSTOMER'], '/ruta-desconocida', routeMap),
        isTrue,
      );
    });

    test('debe retornar false cuando roles es null', () {
      expect(RoleGuard.isRouteAllowed(null, '/users', routeMap), isFalse);
    });

    test('debe retornar false cuando roles está vacío', () {
      expect(RoleGuard.isRouteAllowed([], '/users', routeMap), isFalse);
    });
  });
}
