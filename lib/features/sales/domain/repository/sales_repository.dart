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

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';

import '../entities/sale.dart';

/// Repositorio de Ventas.
///
/// Métodos:
/// - [getProducts]: obtiene la lista de productos disponibles
/// - [getBatchesByProduct]: obtiene los lotes de un producto
/// - [createSale]: crea una venta con lógica FIFO
/// - [getDrafts]: lista los borradores de ventas offline
/// - [confirmDraft]: confirma un borrador enviándolo al backend
abstract class SalesRepository {
  /// Obtiene la lista de productos disponibles.
  ///
  /// Retorna [List<ProductResponse>] con todos los productos.
  /// Lanza [ApiException] en caso de error de red.
  Future<List<ProductResponse>> getProducts({CancelToken? cancelToken});

  /// Obtiene los lotes de producción de un producto específico.
  ///
  /// [productId]: ID del producto a consultar.
  /// Retorna [List<ProductionBatchResponse>] con los lotes activos.
  /// Lanza [ApiException] en caso de error de red.
  Future<List<ProductionBatchResponse>> getBatchesByProduct(
    int productId, {
    CancelToken? cancelToken,
  });

  /// Obtiene la lista de ventas desde el backend.
  ///
  /// Retorna [List<Sale>] con todas las ventas.
  /// Lanza [ApiException] en caso de error de red.
  Future<List<Sale>> getSales({CancelToken? cancelToken});

  /// Obtiene una venta por su ID.
  ///
  /// [id]: ID de la venta a consultar.
  /// Retorna [Sale] con los datos de la venta.
  /// Lanza [ApiException] si no existe o hay error de red.
  Future<Sale> getSaleById(int id, {CancelToken? cancelToken});

  /// Crea una nueva venta en el backend.
  ///
  /// [request]: datos de la venta (productId, quantity).
  /// Retorna [Sale] con los datos de la venta creada.
  /// Lanza [ApiException] en caso de error (stock insuficiente, etc.).
  Future<Sale> createSale(SaleRequest request, {CancelToken? cancelToken});

  /// Obtiene todos los borradores de ventas con status 'draft'.
  ///
  /// Retorna [List<DraftSale>] ordenada por fecha de creación descendente.
  Future<List<DraftSale>> getDrafts();

  /// Confirma un borrador enviándolo al backend.
  ///
  /// [draftId]: ID del borrador a confirmar.
  /// Lee el borrador de la DB, lo envía vía [createSale],
  /// y si el backend responde OK, lo marca como 'confirmed'.
  /// Si el backend falla, propaga [ApiException] y NO cambia el status.
  Future<Sale> confirmDraft(int draftId);
}
