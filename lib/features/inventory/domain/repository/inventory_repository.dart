// Contrato abstracto del repositorio de Inventario.
//
// Define la interfaz que la capa de presentación (Provider)
// usa para consultar inventario y ajustar stock,
// sin depender de implementaciones concretas de red.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo tipos de Dart puro y modelos del dominio.
//
// TDD: GREEN — implementación mínima para pasar los tests

import '../entities/stock_item.dart';
import '../entities/adjustment.dart';

/// Repositorio de Inventario.
///
/// Métodos:
/// - [getInventory]: obtiene el stock de un producto por ID
/// - [getLowStock]: obtiene la lista de productos con stock bajo
/// - [adjustStock]: ajusta el stock de un producto
abstract class InventoryRepository {
  /// Obtiene los datos de inventario de un producto específico.
  ///
  /// [productId]: ID del producto a consultar.
  /// Retorna [StockItem] con los datos de stock.
  /// Lanza [ApiException] en caso de error de red.
  Future<StockItem> getInventory(int productId);

  /// Obtiene la lista de productos con stock por debajo del umbral.
  ///
  /// Retorna [List<StockItem>] con los productos críticos.
  /// Lanza [ApiException] en caso de error de red.
  Future<List<StockItem>> getLowStock();

  /// Ajusta el stock de un producto en el backend.
  ///
  /// [productId]: ID del producto a ajustar.
  /// [adjustment]: datos del ajuste (tipo, cantidad, motivo).
  /// Retorna [StockItem] con los datos actualizados.
  /// Lanza [ApiException] en caso de error (400/409).
  Future<StockItem> adjustStock(int productId, Adjustment adjustment);
}
