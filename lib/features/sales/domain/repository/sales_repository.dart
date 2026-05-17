// Contrato abstracto del repositorio de Ventas.
//
// Define la interfaz que la capa de presentación (Provider)
// usa para crear ventas, obtener productos y consultar lotes,
// sin depender de implementaciones concretas de red.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo tipos de Dart puro y modelos del dominio.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';

/// Repositorio de Ventas.
///
/// Métodos:
/// - [getProducts]: obtiene la lista de productos disponibles
/// - [getBatchesByProduct]: obtiene los lotes de un producto
/// - [createSale]: crea una venta con lógica FIFO
abstract class SalesRepository {
  /// Obtiene la lista de productos disponibles.
  ///
  /// Retorna [List<ProductResponse>] con todos los productos.
  /// Lanza [ApiException] en caso de error de red.
  Future<List<ProductResponse>> getProducts();

  /// Obtiene los lotes de producción de un producto específico.
  ///
  /// [productId]: ID del producto a consultar.
  /// Retorna [List<ProductionBatchResponse>] con los lotes activos.
  /// Lanza [ApiException] en caso de error de red.
  Future<List<ProductionBatchResponse>> getBatchesByProduct(int productId);

  /// Crea una nueva venta en el backend.
  ///
  /// [request]: datos de la venta (productId, quantity).
  /// Retorna [SaleResponse] con los datos de la venta creada.
  /// Lanza [ApiException] en caso de error (stock insuficiente, etc.).
  Future<SaleResponse> createSale(SaleRequest request);
}
