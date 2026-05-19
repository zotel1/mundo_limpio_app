// DAO para la tabla InventoryPendingQueue.
//
// Operaciones definidas por el diseño:
// - insert: encola un ajuste de inventario (retorna ID)
// - getAllByStatus: obtiene operaciones por status (FIFO: ASC por createdAt)
// - updateStatus: actualiza status, mensaje de error
// - incrementRetry: incrementa el contador de reintentos
// - delete: elimina una operación por ID
// - countByStatus: cuenta operaciones por status
//
// TDD: GREEN — implementación mínima para pasar inventory_pending_dao_test.dart

import 'package:drift/drift.dart';

import '../app_database.dart';

/// Acceso a datos de la tabla [InventoryPendingQueue].
class InventoryPendingDao {
  final AppDatabase _db;

  InventoryPendingDao(this._db);

  /// Encola un nuevo ajuste de inventario. Retorna el ID generado.
  Future<int> insert(InventoryPendingQueueCompanion op) {
    return _db.into(_db.inventoryPendingQueue).insert(op);
  }

  /// Obtiene todas las operaciones con un status dado,
  /// ordenadas por createdAt ASC (FIFO: más antiguas primero).
  Future<List<InventoryPendingQueueData>> getAllByStatus(String status) {
    return (_db.select(_db.inventoryPendingQueue)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Actualiza el status de una operación.
  ///
  /// [errorMessage] es opcional — se usa cuando el status es 'failed'.
  Future<void> updateStatus(int id, String status, [String? errorMessage]) {
    return (_db.update(
      _db.inventoryPendingQueue,
    )..where((t) => t.id.equals(id))).write(
      InventoryPendingQueueCompanion(
        status: Value(status),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  /// Incrementa el contador de reintentos de una operación.
  ///
  /// Usado por SyncService antes de reintentar una operación fallida.
  Future<void> incrementRetry(int id) async {
    final current = await (_db.select(
      _db.inventoryPendingQueue,
    )..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(
      _db.inventoryPendingQueue,
    )..where((t) => t.id.equals(id))).write(
      InventoryPendingQueueCompanion(retryCount: Value(current.retryCount + 1)),
    );
  }

  /// Elimina una operación por su ID.
  Future<void> delete(int id) {
    return (_db.delete(
      _db.inventoryPendingQueue,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Cuenta operaciones por status.
  Future<int> countByStatus(String status) async {
    final query = _db.selectOnly(_db.inventoryPendingQueue)
      ..addColumns([_db.inventoryPendingQueue.id.count()])
      ..where(_db.inventoryPendingQueue.status.equals(status));
    final row = await query.getSingle();
    return row.read(_db.inventoryPendingQueue.id.count()) ?? 0;
  }
}
