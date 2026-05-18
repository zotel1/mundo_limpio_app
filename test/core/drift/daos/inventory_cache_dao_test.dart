// Pruebas unitarias para InventoryCacheDao.
// Verifica las operaciones del diseño:
// - upsertAll: inserta o actualiza inventario en batch
// - getAll: obtiene todo el inventario cacheado
// - getByProductId: obtiene inventario de un producto
// - deleteAll: vacía el caché de inventario
// - count: cuenta registros
//
// TDD: RED — test escrito antes que la implementación del DAO

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_cache_dao.dart';

void main() {
  late AppDatabase db;
  late InventoryCacheDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = InventoryCacheDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('InventoryCacheDao', () {
    group('upsertAll', () {
      test('debe insertar registros de inventario en el caché', () async {
        final now = DateTime(2026, 5, 18);
        final items = [
          InventoryCacheData(
            productId: 1, productName: 'Jabón', currentStock: 50.0,
            minStockThreshold: 10.0, updatedAt: now,
          ),
          InventoryCacheData(
            productId: 2, productName: 'Cloro', currentStock: 30.0,
            minStockThreshold: 5.0, updatedAt: now,
          ),
        ];

        await dao.upsertAll(items);

        final all = await dao.getAll();
        expect(all, hasLength(2));
        expect(all.map((i) => i.productName), containsAll(['Jabón', 'Cloro']));
      });

      test('debe actualizar inventario existente por productId (PK)', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          InventoryCacheData(
            productId: 1, productName: 'Jabón', currentStock: 50.0,
            minStockThreshold: 10.0, updatedAt: now,
          ),
        ]);

        // Mismo productId, stock actualizado
        await dao.upsertAll([
          InventoryCacheData(
            productId: 1, productName: 'Jabón', currentStock: 25.0,
            minStockThreshold: 10.0, updatedAt: now,
          ),
        ]);

        final all = await dao.getAll();
        expect(all, hasLength(1));
        expect(all.first.currentStock, 25.0);
      });
    });

    group('getAll', () {
      test('debe retornar lista vacía cuando no hay datos', () async {
        final all = await dao.getAll();
        expect(all, isEmpty);
      });
    });

    group('getByProductId', () {
      test('debe retornar el inventario del producto especificado', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          InventoryCacheData(
            productId: 1, productName: 'Jabón', currentStock: 50.0,
            minStockThreshold: 10.0, updatedAt: now,
          ),
          InventoryCacheData(
            productId: 2, productName: 'Cloro', currentStock: 30.0,
            minStockThreshold: 5.0, updatedAt: now,
          ),
        ]);

        final result = await dao.getByProductId(2);
        expect(result, isNotNull);
        expect(result!.productName, 'Cloro');
        expect(result.currentStock, 30.0);
      });

      test('debe retornar null si el producto no está cacheado', () async {
        final result = await dao.getByProductId(999);
        expect(result, isNull);
      });
    });

    group('deleteAll', () {
      test('debe eliminar todo el inventario cacheado', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          InventoryCacheData(
            productId: 1, productName: 'Jabón', currentStock: 50.0,
            minStockThreshold: 10.0, updatedAt: now,
          ),
        ]);

        await dao.deleteAll();
        final all = await dao.getAll();
        expect(all, isEmpty);
      });
    });

    group('count', () {
      test('debe retornar la cantidad de registros', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          InventoryCacheData(
            productId: 1, productName: 'P1', currentStock: 10.0,
            minStockThreshold: 5.0, updatedAt: now,
          ),
          InventoryCacheData(
            productId: 2, productName: 'P2', currentStock: 20.0,
            minStockThreshold: 5.0, updatedAt: now,
          ),
        ]);

        expect(await dao.count(), 2);
      });
    });
  });
}
