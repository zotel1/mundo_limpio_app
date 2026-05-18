// DAO para la tabla BatchCache.
//
// Operaciones definidas por el diseño:
// - upsertAll: inserta o reemplaza lotes en batch
// - getByProductId: obtiene todos los lotes cacheados de un producto
// - deleteByProductId: elimina los lotes de un producto específico
// - deleteAll: vacía el caché de lotes
// - count: cuenta registros en el caché
//
// TDD: GREEN — implementación mínima para pasar batch_cache_dao_test.dart

import 'package:drift/drift.dart';

import '../app_database.dart';

/// Acceso a datos de la tabla [BatchCache].
class BatchCacheDao {
  final AppDatabase _db;

  BatchCacheDao(this._db);

  /// Inserta o actualiza múltiples lotes en el caché.
  Future<void> upsertAll(List<BatchCacheData> batches) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.batchCache, batches);
    });
  }

  /// Obtiene todos los lotes cacheados para un producto dado.
  Future<List<BatchCacheData>> getByProductId(int productId) {
    return (_db.select(_db.batchCache)
          ..where((t) => t.productId.equals(productId)))
        .get();
  }

  /// Elimina todos los lotes cacheados de un producto específico.
  Future<void> deleteByProductId(int productId) {
    return (_db.delete(_db.batchCache)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }

  /// Obtiene todos los lotes cacheados (para deleteAll + tests).
  Future<List<BatchCacheData>> getAll() {
    return _db.select(_db.batchCache).get();
  }

  /// Elimina todos los lotes del caché.
  Future<void> deleteAll() {
    return _db.delete(_db.batchCache).go();
  }

  /// Cuenta la cantidad de registros en el caché.
  Future<int> count() async {
    final query = _db.selectOnly(_db.batchCache)
      ..addColumns([_db.batchCache.id.count()]);
    final row = await query.getSingle();
    return row.read(_db.batchCache.id.count()) ?? 0;
  }
}
