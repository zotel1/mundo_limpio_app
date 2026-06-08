// Pruebas para AppDatabase — verifica que el esquema Drift se crea
// correctamente con las 5 tablas definidas en el diseño.
//
// TDD: RED — test escrito antes que la implementación del AppDatabase

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('debe inicializar la base de datos sin errores', () async {
      expect(db, isNotNull);
      expect(db.schemaVersion, 3);
    });

    test('debe tener las 5 tablas del esquema de diseño', () async {
      // ProductCache — id es Value (opcional, PK), name/updatedAt son raw
      await db
          .into(db.productCache)
          .insert(
            ProductCacheCompanion.insert(
              id: const Value(1),
              name: 'Test',
              updatedAt: DateTime(2026, 1, 1),
            ),
          );
      final products = await db.select(db.productCache).get();
      expect(products, hasLength(1));
      expect(products.first.name, 'Test');

      // BatchCache
      await db
          .into(db.batchCache)
          .insert(
            BatchCacheCompanion.insert(
              id: const Value(1),
              productId: 1,
              currentStock: 100.0,
              updatedAt: DateTime(2026, 1, 1),
            ),
          );
      final batches = await db.select(db.batchCache).get();
      expect(batches, hasLength(1));
      expect(batches.first.currentStock, 100.0);

      // InventoryCache — productId es Value (PK, opcional)
      await db
          .into(db.inventoryCache)
          .insert(
            InventoryCacheCompanion.insert(
              productId: const Value(2),
              productName: 'Test Product',
              currentStock: 50.0,
              minStockThreshold: 10.0,
              updatedAt: DateTime(2026, 1, 1),
            ),
          );
      final inventory = await db.select(db.inventoryCache).get();
      expect(inventory, hasLength(1));
      expect(inventory.first.productName, 'Test Product');

      // DraftSales — id, status, createdAt, confirmedAt tienen defaults
      final draftId = await db
          .into(db.draftSales)
          .insert(
            DraftSalesCompanion.insert(
              productId: 1,
              productName: 'Draft Product',
              batchId: 1,
              quantity: 10.0,
              unitPrice: 150.0,
              status: const Value('draft'),
            ),
          );
      expect(draftId, greaterThan(0));
      final drafts = await db.select(db.draftSales).get();
      expect(drafts, hasLength(1));
      expect(drafts.first.status, 'draft');

      // InventoryPendingQueue — id, status, createdAt, etc. con defaults
      final pendingId = await db
          .into(db.inventoryPendingQueue)
          .insert(
            InventoryPendingQueueCompanion.insert(
              productId: 1,
              payload: '{"type":"add","quantity":5}',
              status: const Value('pending'),
            ),
          );
      expect(pendingId, greaterThan(0));
      final pending = await db.select(db.inventoryPendingQueue).get();
      expect(pending, hasLength(1));
      expect(pending.first.status, 'pending');
    });

    test('debe ser instancia de AppDatabase', () {
      expect(db, isA<AppDatabase>());
    });

    test('debe permitir insertar múltiples registros en cada tabla', () async {
      // ProductCache: 3 registros
      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.productCache)
            .insert(
              ProductCacheCompanion.insert(
                id: Value(i),
                name: 'Product $i',
                updatedAt: DateTime(2026, 1, i),
              ),
            );
      }
      final allProducts = await db.select(db.productCache).get();
      expect(allProducts, hasLength(3));

      // BatchCache: 2 registros mismo productId
      for (var i = 1; i <= 2; i++) {
        await db
            .into(db.batchCache)
            .insert(
              BatchCacheCompanion.insert(
                id: Value(i),
                productId: 1,
                currentStock: 100.0 * i,
                updatedAt: DateTime(2026, 1, i),
              ),
            );
      }
      final allBatches = await db.select(db.batchCache).get();
      expect(allBatches, hasLength(2));
    });
  });
}
