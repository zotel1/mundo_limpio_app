// Pruebas unitarias para DraftSaleDao.
// Verifica las operaciones del diseño:
// - insert: crea un borrador con auto-increment ID
// - getById: obtiene un borrador por su ID
// - getAllByStatus: lista borradores filtrados por status, DESC por createdAt
// - updateStatus: cambia el status de un borrador
// - countByStatus: cuenta borradores en un estado
// - delete: elimina un borrador por ID
//
// TDD: RED — test escrito antes que la implementación del DAO

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/draft_sale_dao.dart';

void main() {
  late AppDatabase db;
  late DraftSaleDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = DraftSaleDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DraftSaleDao', () {
    group('insert', () {
      test('debe insertar un borrador y retornar ID > 0', () async {
        final id = await dao.insert(
          DraftSalesCompanion.insert(
            productId: 1,
            productName: 'Producto Test',
            batchId: 42,
            quantity: 10.0,
            unitPrice: 150.0,
            status: const Value('draft'),
          ),
        );

        expect(id, greaterThan(0));
      });

      test('debe guardar el status por defecto como draft', () async {
        final id = await dao.insert(
          DraftSalesCompanion.insert(
            productId: 1,
            productName: 'Producto Test',
            batchId: 42,
            quantity: 10.0,
            unitPrice: 150.0,
          ),
        );

        final draft = await dao.getById(id);
        expect(draft, isNotNull);
        expect(draft!.status, 'draft');
      });
    });

    group('getById', () {
      test('debe retornar el borrador por ID', () async {
        final id = await dao.insert(
          DraftSalesCompanion.insert(
            productId: 1,
            productName: 'Test',
            batchId: 1,
            quantity: 5.0,
            unitPrice: 100.0,
          ),
        );

        final draft = await dao.getById(id);
        expect(draft, isNotNull);
        expect(draft!.productName, 'Test');
        expect(draft.quantity, 5.0);
      });

      test('debe retornar null si el ID no existe', () async {
        final draft = await dao.getById(999);
        expect(draft, isNull);
      });
    });

    group('getAllByStatus', () {
      test('debe retornar borradores filtrados por status', () async {
        await _insertDraft(dao, 1, 'P1', 'draft');
        await _insertDraft(dao, 2, 'P2', 'confirmed');
        await _insertDraft(dao, 3, 'P3', 'draft');

        final drafts = await dao.getAllByStatus('draft');
        expect(drafts, hasLength(2));
        expect(drafts.every((d) => d.status == 'draft'), isTrue);
      });

      test('debe retornar ordenados por createdAt DESC', () async {
        final id1 = await _insertDraftWithCreatedAt(
          dao,
          1,
          'Primero',
          DateTime(2026, 5, 1, 10, 0, 0),
        );
        final id2 = await _insertDraftWithCreatedAt(
          dao,
          2,
          'Segundo',
          DateTime(2026, 5, 18, 10, 0, 0),
        );

        final drafts = await dao.getAllByStatus('draft');
        expect(drafts, hasLength(2));
        // El más reciente (Segundo) debe aparecer primero
        expect(drafts.first.id, id2);
        expect(drafts.last.id, id1);
      });
    });

    group('updateStatus', () {
      test('debe cambiar el status de draft a confirmed', () async {
        final id = await _insertDraft(dao, 1, 'Test', 'draft');

        await dao.updateStatus(id, 'confirmed');

        final draft = await dao.getById(id);
        expect(draft!.status, 'confirmed');
      });

      test('debe cambiar el status de draft a cancelled', () async {
        final id = await _insertDraft(dao, 1, 'Test', 'draft');

        await dao.updateStatus(id, 'cancelled');

        final draft = await dao.getById(id);
        expect(draft!.status, 'cancelled');
      });
    });

    group('countByStatus', () {
      test('debe contar borradores por status', () async {
        await _insertDraft(dao, 1, 'P1', 'draft');
        await _insertDraft(dao, 2, 'P2', 'draft');
        await _insertDraft(dao, 3, 'P3', 'confirmed');

        expect(await dao.countByStatus('draft'), 2);
        expect(await dao.countByStatus('confirmed'), 1);
        expect(await dao.countByStatus('cancelled'), 0);
      });
    });

    group('delete', () {
      test('debe eliminar un borrador por ID', () async {
        final id = await _insertDraft(dao, 1, 'Test', 'draft');

        await dao.delete(id);

        final draft = await dao.getById(id);
        expect(draft, isNull);
      });

      test('delete no debe fallar con ID inexistente', () async {
        await dao.delete(999);
        // No debe lanzar excepción
      });
    });
  });
}

/// Helper: inserta un borrador y retorna su ID.
Future<int> _insertDraft(
  DraftSaleDao dao,
  int productId,
  String productName,
  String status,
) {
  return dao.insert(
    DraftSalesCompanion.insert(
      productId: productId,
      productName: productName,
      batchId: 1,
      quantity: 10.0,
      unitPrice: 100.0,
      status: Value(status),
    ),
  );
}

/// Helper: inserta un borrador con createdAt explícito.
Future<int> _insertDraftWithCreatedAt(
  DraftSaleDao dao,
  int productId,
  String productName,
  DateTime createdAt,
) {
  return dao.insert(
    DraftSalesCompanion.insert(
      productId: productId,
      productName: productName,
      batchId: 1,
      quantity: 10.0,
      unitPrice: 100.0,
      status: const Value('draft'),
      createdAt: Value(createdAt),
    ),
  );
}
