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

import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';

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
  /// Retorna [InventoryResponse] con los datos de stock.
  /// Lanza [ApiException] en caso de error de red.
  Future<InventoryResponse> getInventory(int productId);

  /// Obtiene la lista de productos con stock por debajo del umbral.
  ///
  /// Retorna [List<InventoryResponse>] con los productos críticos.
  /// Lanza [ApiException] en caso de error de red.
  Future<List<InventoryResponse>> getLowStock();

  /// Ajusta el stock de un producto en el backend.
  ///
  /// [productId]: ID del producto a ajustar.
  /// [request]: datos del ajuste (tipo, cantidad, motivo).
  /// Retorna [InventoryResponse] con los datos actualizados.
  /// Lanza [ApiException] en caso de error (400/409).
  Future<InventoryResponse> adjustStock(
      int productId, AdjustmentRequest request);
}
