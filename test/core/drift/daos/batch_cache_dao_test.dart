// Pruebas unitarias para BatchCacheDao.
// Verifica las operaciones del diseño:
// - upsertAll: inserta o actualiza lotes en batch
// - getByProductId: obtiene lotes de un producto específico
// - deleteByProductId: elimina lotes de un producto
// - deleteAll: vacía el caché de lotes
// - count: cuenta registros en la tabla
//
// TDD: RED — test escrito antes que la implementación del DAO

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/batch_cache_dao.dart';

void main() {
  late AppDatabase db;
  late BatchCacheDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = BatchCacheDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BatchCacheDao', () {
    group('upsertAll', () {
      test('debe insertar lotes nuevos en el caché', () async {
        final now = DateTime(2026, 5, 18);
        final batches = [
          BatchCacheData(
            id: 1,
            productId: 10,
            currentStock: 100.0,
            updatedAt: now,
          ),
          BatchCacheData(
            id: 2,
            productId: 10,
            currentStock: 50.0,
            updatedAt: now,
          ),
        ];

        await dao.upsertAll(batches);

        final all = await dao.getAll();
        expect(all, hasLength(2));
      });

      test('debe actualizar lotes existentes por PK', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          BatchCacheData(
            id: 1,
            productId: 10,
            currentStock: 100.0,
            updatedAt: now,
          ),
        ]);

        // Mismo id, nuevo stock
        await dao.upsertAll([
          BatchCacheData(
            id: 1,
            productId: 10,
            currentStock: 75.0,
            updatedAt: now,
          ),
        ]);

        final all = await dao.getAll();
        expect(all, hasLength(1));
        expect(all.first.currentStock, 75.0);
      });
    });

    group('getByProductId', () {
      test('debe retornar lista vacía si no hay lotes del producto', () async {
        final result = await dao.getByProductId(999);
        expect(result, isEmpty);
      });

      test('debe retornar solo los lotes del producto especificado', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          BatchCacheData(
            id: 1,
            productId: 10,
            currentStock: 100.0,
            updatedAt: now,
          ),
          BatchCacheData(
            id: 2,
            productId: 10,
            currentStock: 50.0,
            updatedAt: now,
          ),
          BatchCacheData(
            id: 3,
            productId: 20,
            currentStock: 30.0,
            updatedAt: now,
          ),
        ]);

        final result = await dao.getByProductId(10);
        expect(result, hasLength(2));
        expect(result.every((b) => b.productId == 10), isTrue);
      });
    });

    group('deleteByProductId', () {
      test('debe eliminar solo los lotes del producto especificado', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          BatchCacheData(
            id: 1,
            productId: 10,
            currentStock: 100.0,
            updatedAt: now,
          ),
          BatchCacheData(
            id: 2,
            productId: 10,
            currentStock: 50.0,
            updatedAt: now,
          ),
          BatchCacheData(
            id: 3,
            productId: 20,
            currentStock: 30.0,
            updatedAt: now,
          ),
        ]);

        await dao.deleteByProductId(10);

        final all = await dao.getAll();
        expect(all, hasLength(1));
        expect(all.first.productId, 20);
      });

      test('deleteByProductId no debe fallar sin coincidencias', () async {
        await dao.deleteByProductId(999);
        // No debe lanzar excepción
      });
    });

    group('deleteAll', () {
      test('debe eliminar todos los lotes del caché', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          BatchCacheData(
            id: 1,
            productId: 10,
            currentStock: 100.0,
            updatedAt: now,
          ),
          BatchCacheData(
            id: 2,
            productId: 20,
            currentStock: 50.0,
            updatedAt: now,
          ),
        ]);

        await dao.deleteAll();
        final all = await dao.getAll();
        expect(all, isEmpty);
      });
    });

    group('count', () {
      test('debe retornar la cantidad de lotes cacheados', () async {
        final now = DateTime(2026, 5, 18);
        await dao.upsertAll([
          BatchCacheData(
            id: 1,
            productId: 10,
            currentStock: 100.0,
            updatedAt: now,
          ),
          BatchCacheData(
            id: 2,
            productId: 20,
            currentStock: 50.0,
            updatedAt: now,
          ),
          BatchCacheData(
            id: 3,
            productId: 30,
            currentStock: 30.0,
            updatedAt: now,
          ),
        ]);

        expect(await dao.count(), 3);
      });
    });
  });
}
