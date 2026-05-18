// DAO para la tabla DraftSales.
//
// Operaciones definidas por el diseño:
// - insert: crea un borrador (retorna ID auto-incremental)
// - getById: obtiene un borrador por su ID
// - getAllByStatus: lista borradores por status, ordenados DESC por createdAt
// - updateStatus: cambia el status (draft → confirmed | cancelled)
// - countByStatus: cuenta borradores en un estado
// - delete: elimina un borrador por ID
//
// TDD: GREEN — implementación mínima para pasar draft_sale_dao_test.dart

import 'package:drift/drift.dart';

import '../app_database.dart';

/// Acceso a datos de la tabla [DraftSales].
class DraftSaleDao {
  final AppDatabase _db;

  DraftSaleDao(this._db);

  /// Inserta un nuevo borrador de venta. Retorna el ID generado.
  Future<int> insert(DraftSalesCompanion draft) {
    return _db.into(_db.draftSales).insert(draft);
  }

  /// Obtiene un borrador por su ID, o null si no existe.
  Future<DraftSale?> getById(int id) {
    return (_db.select(_db.draftSales)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Obtiene todos los borradores con un status dado,
  /// ordenados del más reciente al más antiguo.
  Future<List<DraftSale>> getAllByStatus(String status) {
    return (_db.select(_db.draftSales)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Actualiza el status de un borrador.
  Future<void> updateStatus(int id, String status) {
    return (_db.update(_db.draftSales)..where((t) => t.id.equals(id)))
        .write(DraftSalesCompanion(status: Value(status)));
  }

  /// Cuenta borradores por status.
  Future<int> countByStatus(String status) async {
    final query = _db.selectOnly(_db.draftSales)
      ..addColumns([_db.draftSales.id.count()])
      ..where(_db.draftSales.status.equals(status));
    final row = await query.getSingle();
    return row.read(_db.draftSales.id.count()) ?? 0;
  }

  /// Elimina un borrador por su ID.
  Future<void> delete(int id) {
    return (_db.delete(_db.draftSales)..where((t) => t.id.equals(id))).go();
  }
}
