// Pruebas unitarias para ProductCacheDao.
// Verifica las 4 operaciones del diseño:
// - upsertAll: inserta o actualiza productos en batch
// - getAll: obtiene todos los productos cacheados
// - deleteAll: elimina todo el caché de productos
// - count: cuenta registros en la tabla
//
// TDD: RED — test escrito antes que la implementación del DAO

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/product_cache_dao.dart';

void main() {
  late AppDatabase db;
  late ProductCacheDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ProductCacheDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProductCacheDao', () {
    group('upsertAll', () {
      test('debe insertar productos nuevos en el caché', () async {
        // Arrange
        final now = DateTime(2026, 5, 18);
        final products = [
          ProductCacheData(id: 1, name: 'Producto A', updatedAt: now),
          ProductCacheData(id: 2, name: 'Producto B', updatedAt: now),
        ];

        // Act
        await dao.upsertAll(products);

        // Assert
        final all = await dao.getAll();
        expect(all, hasLength(2));
        expect(all.map((p) => p.name), containsAll(['Producto A', 'Producto B']));
      });

      test('debe actualizar productos existentes por PK', () async {
        // Arrange: insertar un producto primero
        await dao.upsertAll([
          ProductCacheData(id: 1, name: 'Original', updatedAt: DateTime(2026, 5, 18)),
        ]);

        // Act: upsert con nuevo nombre (mismo id)
        await dao.upsertAll([
          ProductCacheData(id: 1, name: 'Actualizado', updatedAt: DateTime(2026, 5, 18)),
        ]);

        // Assert: solo 1 registro, con el nombre nuevo
        final all = await dao.getAll();
        expect(all, hasLength(1));
        expect(all.first.name, 'Actualizado');
      });
    });

    group('getAll', () {
      test('debe retornar lista vacía cuando no hay datos', () async {
        final all = await dao.getAll();
        expect(all, isEmpty);
      });

      test('debe retornar todos los productos insertados', () async {
        await dao.upsertAll([
          ProductCacheData(id: 1, name: 'P1', updatedAt: DateTime(2026, 5, 18)),
          ProductCacheData(id: 2, name: 'P2', updatedAt: DateTime(2026, 5, 18)),
          ProductCacheData(id: 3, name: 'P3', updatedAt: DateTime(2026, 5, 18)),
        ]);

        final all = await dao.getAll();
        expect(all, hasLength(3));
        expect(all[0].id, 1);
        expect(all[1].id, 2);
        expect(all[2].id, 3);
      });
    });

    group('deleteAll', () {
      test('debe eliminar todos los productos del caché', () async {
        // Arrange
        await dao.upsertAll([
          ProductCacheData(id: 1, name: 'P1', updatedAt: DateTime(2026, 5, 18)),
          ProductCacheData(id: 2, name: 'P2', updatedAt: DateTime(2026, 5, 18)),
        ]);

        // Act
        await dao.deleteAll();

        // Assert
        final all = await dao.getAll();
        expect(all, isEmpty);
      });

      test('deleteAll no debe fallar con caché vacío', () async {
        await dao.deleteAll();
        final all = await dao.getAll();
        expect(all, isEmpty);
      });
    });

    group('count', () {
      test('debe retornar 0 cuando el caché está vacío', () async {
        final result = await dao.count();
        expect(result, 0);
      });

      test('debe retornar la cantidad exacta de productos cacheados', () async {
        await dao.upsertAll([
          ProductCacheData(id: 1, name: 'P1', updatedAt: DateTime(2026, 5, 18)),
          ProductCacheData(id: 2, name: 'P2', updatedAt: DateTime(2026, 5, 18)),
          ProductCacheData(id: 3, name: 'P3', updatedAt: DateTime(2026, 5, 18)),
        ]);

        final result = await dao.count();
        expect(result, 3);
      });
    });
  });
}
