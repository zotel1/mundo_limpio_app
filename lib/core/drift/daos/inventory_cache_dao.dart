// DAO para la tabla InventoryCache.
//
// Operaciones definidas por el diseño:
// - upsertAll: inserta o reemplaza datos de inventario en batch
// - getAll: obtiene todo el inventario cacheado
// - getByProductId: obtiene inventario de un producto (nullable)
// - deleteAll: vacía el caché de inventario
// - count: cuenta registros
//
// TDD: GREEN — implementación mínima para pasar inventory_cache_dao_test.dart

import 'package:drift/drift.dart';

import '../app_database.dart';

/// Acceso a datos de la tabla [InventoryCache].
class InventoryCacheDao {
  final AppDatabase _db;

  InventoryCacheDao(this._db);

  /// Inserta o actualiza múltiples registros de inventario.
  Future<void> upsertAll(List<InventoryCacheData> items) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.inventoryCache, items);
    });
  }

  /// Obtiene todos los registros de inventario cacheado.
  Future<List<InventoryCacheData>> getAll() {
    return _db.select(_db.inventoryCache).get();
  }

  /// Obtiene el inventario cacheado de un producto, o null si no existe.
  Future<InventoryCacheData?> getByProductId(int productId) {
    return (_db.select(
      _db.inventoryCache,
    )..where((t) => t.productId.equals(productId))).getSingleOrNull();
  }

  /// Elimina todos los registros de inventario.
  Future<void> deleteAll() {
    return _db.delete(_db.inventoryCache).go();
  }

  /// Cuenta la cantidad de registros en el caché.
  Future<int> count() async {
    final query = _db.selectOnly(_db.inventoryCache)
      ..addColumns([_db.inventoryCache.productId.count()]);
    final row = await query.getSingle();
    return row.read(_db.inventoryCache.productId.count()) ?? 0;
  }
}
