// Base de datos SQLite local con Drift para persistencia offline.
//
// Define 5 tablas siguiendo el diseño de la arquitectura offline-first:
// - ProductCache, BatchCache: cache de GETs del módulo de Ventas
// - InventoryCache: cache de GETs del módulo de Inventario
// - DraftSales: borradores de ventas creadas offline
// - InventoryPendingQueue: cola de ajustes de inventario pendientes de sync
//
// En producción usa el sistema de archivos (getApplicationDocumentsDirectory).
// En tests acepta un QueryExecutor opcional (ej: NativeDatabase.memory()).
//
// TDD: GREEN — implementación mínima para pasar app_database_test.dart

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ─── Cache Tables ──────────────────────────────────────────────

/// Cache local de productos obtenidos del backend.
///
/// Cada fila representa un producto cacheado con su ID, nombre,
/// SKU opcional, precio mínimo opcional, estado activo/inactivo
/// y timestamp de última actualización.
class ProductCache extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn? get sku => text().nullable()();
  RealColumn? get minPrice => real().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache local de lotes de producción obtenidos del backend.
///
/// Cada fila representa un lote con su ID, producto asociado,
/// stock actual y timestamp de última actualización.
class BatchCache extends Table {
  IntColumn get id => integer()();
  IntColumn get productId => integer()();
  RealColumn get currentStock => real()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache local de datos de inventario por producto.
///
/// Almacena producto, stock actual, umbral mínimo y timestamp.
class InventoryCache extends Table {
  IntColumn get productId => integer()();
  TextColumn get productName => text()();
  RealColumn get currentStock => real()();
  RealColumn get minStockThreshold => real()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {productId};
}

// ─── Draft Sales Table ─────────────────────────────────────────

/// Borradores de ventas creadas offline.
///
/// Cada borrador guarda los datos de la venta (producto, lote,
/// cantidad, precio) y su estado de ciclo de vida:
/// 'draft' → 'confirmed' | 'cancelled'.
class DraftSales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer()();
  TextColumn get productName => text()();
  IntColumn get batchId => integer()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
}

// ─── Inventory Pending Queue ───────────────────────────────────

/// Cola de ajustes de inventario pendientes de sincronizar.
///
/// Cada fila es una operación de ajuste (add/remove) que se
/// encoló offline y espera ser enviada al reconectar.
class InventoryPendingQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

// ─── Database ──────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    ProductCache,
    BatchCache,
    InventoryCache,
    DraftSales,
    InventoryPendingQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Crea la base de datos.
  ///
  /// Si no se provee [e], usa el sistema de archivos en
  /// `getApplicationDocumentsDirectory()`.
  /// Para tests, pasar [NativeDatabase.memory()].
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_draft_sales_status '
          'ON draft_sales (status)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_batch_cache_product_id '
          'ON batch_cache (product_id)',
        );
      },
      onUpgrade: (migrator, from, to) async {
        if (from == 1) {
          await migrator.addColumn(productCache, productCache.sku);
          await migrator.addColumn(productCache, productCache.minPrice);
          await migrator.addColumn(productCache, productCache.active);
          // Asegurar que filas existentes tengan active = true
          // (ALTER TABLE ADD COLUMN con DEFAULT no siempre se aplica
          // a filas existentes en todas las versiones de SQLite)
          await customStatement(
            'UPDATE product_cache SET active = 1 WHERE active IS NULL',
          );
        }
        if (from < 3) {
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_draft_sales_status '
            'ON draft_sales (status)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_batch_cache_product_id '
            'ON batch_cache (product_id)',
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

/// Abre la conexión nativa a SQLite usando el directorio de
/// documentos de la aplicación.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mundolimpio.db'));
    return NativeDatabase.createInBackground(file);
  });
}
