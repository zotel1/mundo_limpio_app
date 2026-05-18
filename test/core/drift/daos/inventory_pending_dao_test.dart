// Pruebas unitarias para InventoryPendingDao.
// Verifica las operaciones del diseño:
// - insert: encola un ajuste de inventario pendiente
// - getAllByStatus: lista operaciones pendientes por status
// - updateStatus: cambia el status y opcionalmente el mensaje de error
// - delete: elimina una operación por ID
// - countByStatus: cuenta operaciones por status
//
// TDD: RED — test escrito antes que la implementación del DAO

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/inventory_pending_dao.dart';

void main() {
  late AppDatabase db;
  late InventoryPendingDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = InventoryPendingDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('InventoryPendingDao', () {
    group('insert', () {
      test('debe encolar un ajuste y retornar ID > 0', () async {
        final id = await dao.insert(InventoryPendingQueueCompanion.insert(
          productId: 1,
          payload: '{"type":"add","quantity":5}',
          status: const Value('pending'),
        ));

        expect(id, greaterThan(0));
      });

      test('debe guardar status pending por defecto', () async {
        final id = await dao.insert(InventoryPendingQueueCompanion.insert(
          productId: 1,
          payload: '{"type":"add","quantity":5}',
        ));

        final all = await dao.getAllByStatus('pending');
        expect(all, hasLength(1));
        expect(all.first.status, 'pending');
      });

      test('debe inicializar retryCount en 0 por defecto', () async {
        final id = await dao.insert(InventoryPendingQueueCompanion.insert(
          productId: 1,
          payload: '{"type":"add","quantity":5}',
        ));

        final all = await dao.getAllByStatus('pending');
        expect(all.first.retryCount, 0);
      });
    });

    group('getAllByStatus', () {
      test('debe retornar vacío si no hay operaciones con ese status', () async {
        final result = await dao.getAllByStatus('failed');
        expect(result, isEmpty);
      });

      test('debe retornar operaciones filtradas por status', () async {
        await _insert(dao, 1, 'pending');
        await _insert(dao, 2, 'pending');
        await _insert(dao, 3, 'failed');

        final pending = await dao.getAllByStatus('pending');
        expect(pending, hasLength(2));
      });

      test('debe retornar orden FIFO (más antiguas primero)', () async {
        final id1 = await _insertWithCreatedAt(
            dao, 1, DateTime(2026, 5, 1));
        final id2 = await _insertWithCreatedAt(
            dao, 2, DateTime(2026, 5, 18));

        final result = await dao.getAllByStatus('pending');
        // FIFO: más antiguo primero
        expect(result.first.id, id1);
        expect(result.last.id, id2);
      });
    });

    group('updateStatus', () {
      test('debe cambiar status de pending a failed con mensaje de error', () async {
        final id = await _insert(dao, 1, 'pending');

        await dao.updateStatus(id, 'failed', 'Stock insuficiente');

        final all = await dao.getAllByStatus('failed');
        expect(all, hasLength(1));
        expect(all.first.errorMessage, 'Stock insuficiente');
      });

      test('debe incrementar retryCount al reintentar', () async {
        final id = await _insert(dao, 1, 'pending');
        await dao.updateStatus(id, 'failed', 'Error 500');
        await dao.incrementRetry(id);

        final all = await dao.getAllByStatus('failed');
        expect(all.first.retryCount, 1);
      });
    });

    group('delete', () {
      test('debe eliminar una operación por ID', () async {
        final id = await _insert(dao, 1, 'pending');

        await dao.delete(id);

        final all = await dao.getAllByStatus('pending');
        expect(all, isEmpty);
      });
    });

    group('countByStatus', () {
      test('debe contar operaciones por status', () async {
        await _insert(dao, 1, 'pending');
        await _insert(dao, 2, 'pending');
        await _insert(dao, 3, 'failed');

        expect(await dao.countByStatus('pending'), 2);
        expect(await dao.countByStatus('failed'), 1);
      });
    });
  });
}

/// Helper: inserta una operación pendiente y retorna su ID.
Future<int> _insert(InventoryPendingDao dao, int productId, String status) {
  return dao.insert(InventoryPendingQueueCompanion.insert(
    productId: productId,
    payload: '{"type":"add","quantity":5}',
    status: Value(status),
  ));
}

/// Helper: inserta con createdAt explícito para pruebas FIFO.
Future<int> _insertWithCreatedAt(
    InventoryPendingDao dao, int productId, DateTime createdAt) {
  return dao.insert(InventoryPendingQueueCompanion.insert(
    productId: productId,
    payload: '{"type":"add","quantity":5}',
    status: const Value('pending'),
    createdAt: Value(createdAt),
  ));
}
