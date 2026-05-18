// DAO para la tabla ProductCache.
//
// Operaciones definidas por el diseño:
// - upsertAll: inserta o reemplaza productos en batch (ON CONFLICT REPLACE)
// - getAll: obtiene todos los productos cacheados
// - deleteAll: vacía el caché de productos
// - count: cuenta la cantidad de registros en el caché
//
// TDD: GREEN — implementación mínima para pasar product_cache_dao_test.dart

import 'package:drift/drift.dart';

import '../app_database.dart';

/// Acceso a datos de la tabla [ProductCache].
///
/// Recibe [AppDatabase] por inyección de dependencia.
class ProductCacheDao {
  final AppDatabase _db;

  /// Crea el DAO con la instancia de base de datos inyectada.
  ProductCacheDao(this._db);

  /// Inserta o actualiza múltiples productos en el caché.
  ///
  /// Usa [InsertMode.insertOrReplace] para que el upsert funcione:
  /// si el registro ya existe (misma PK), se reemplaza.
  Future<void> upsertAll(List<ProductCacheData> products) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.productCache, products);
    });
  }

  /// Obtiene todos los productos cacheados.
  Future<List<ProductCacheData>> getAll() {
    return _db.select(_db.productCache).get();
  }

  /// Elimina todos los productos del caché.
  Future<void> deleteAll() {
    return _db.delete(_db.productCache).go();
  }

  /// Cuenta la cantidad de registros en el caché.
  Future<int> count() async {
    final query = _db.selectOnly(_db.productCache)
      ..addColumns([_db.productCache.id.count()]);
    final row = await query.getSingle();
    return row.read(_db.productCache.id.count()) ?? 0;
  }
}
