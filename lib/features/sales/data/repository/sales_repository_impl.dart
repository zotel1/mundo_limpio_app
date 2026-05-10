// Implementación concreta de SalesRepository.
//
// Delega todas las operaciones en SalesApi (capa HTTP).
// No agrega lógica de negocio — eso pertenece al Provider
// o a futuros casos de uso.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:mundo_limpio_app/features/sales/data/api/sales_api.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';

/// Implementación de [SalesRepository] que usa [SalesApi] para
/// comunicación HTTP con el backend.
///
/// Cada método delega en [SalesApi] y retorna el resultado
/// directamente. Las excepciones de red se propagan como
/// [ApiException] (ya convertidas por SalesApi).
class SalesRepositoryImpl implements SalesRepository {
  final SalesApi _salesApi;

  /// Crea el repositorio con la dependencia inyectada.
  ///
  /// [salesApi]: cliente HTTP para endpoints de ventas.
  const SalesRepositoryImpl({required SalesApi salesApi})
      : _salesApi = salesApi;

  @override
  Future<List<ProductResponse>> getProducts() async {
    return _salesApi.getProducts();
  }

  @override
  Future<List<ProductionBatchResponse>> getBatchesByProduct(
      int productId) async {
    return _salesApi.getBatchesByProduct(productId);
  }

  @override
  Future<SaleResponse> createSale(SaleRequest request) async {
    return _salesApi.createSale(request);
  }
}
