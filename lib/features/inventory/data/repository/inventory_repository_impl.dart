// Implementación concreta de InventoryRepository.
//
// Delega todas las operaciones en InventoryApi (capa HTTP).
// No agrega lógica de negocio — eso pertenece al Provider
// o a futuros casos de uso.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/domain/repository/inventory_repository.dart';

/// Implementación de [InventoryRepository] que usa [InventoryApi] para
/// comunicación HTTP con el backend.
///
/// Cada método delega en [InventoryApi] y retorna el resultado
/// directamente. Las excepciones de red se propagan como
/// [ApiException] (ya convertidas por InventoryApi).
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryApi _inventoryApi;

  /// Crea el repositorio con la dependencia inyectada.
  ///
  /// [inventoryApi]: cliente HTTP para endpoints de inventario.
  const InventoryRepositoryImpl({required InventoryApi inventoryApi})
      : _inventoryApi = inventoryApi;

  @override
  Future<InventoryResponse> getInventory(int productId) async {
    return _inventoryApi.getInventory(productId);
  }

  @override
  Future<List<InventoryResponse>> getLowStock() async {
    return _inventoryApi.getLowStock();
  }

  @override
  Future<InventoryResponse> adjustStock(
      int productId, AdjustmentRequest request) async {
    return _inventoryApi.adjustStock(productId, request);
  }
}
