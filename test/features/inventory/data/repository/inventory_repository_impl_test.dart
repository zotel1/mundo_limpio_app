// Pruebas unitarias para InventoryRepositoryImpl.
// Verifica que el repositorio delega correctamente en InventoryApi:
// - getInventory: llama InventoryApi.getInventory con el ID correcto
// - getLowStock: llama InventoryApi.getLowStock → retorna lista
// - adjustStock: llama InventoryApi.adjustStock con ID y request
// - Errores: propaga ApiException desde InventoryApi
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/data/repository/inventory_repository_impl.dart';

// Mock de InventoryApi para aislar las pruebas del repositorio de la red real
class MockInventoryApi extends Mock implements InventoryApi {}

void main() {
  late MockInventoryApi mockInventoryApi;
  late InventoryRepositoryImpl repository;

  const testProductId = 1;

  setUp(() {
    mockInventoryApi = MockInventoryApi();
    repository = InventoryRepositoryImpl(inventoryApi: mockInventoryApi);
  });

  group('getInventory', () {
    // Verifica que getInventory delega en InventoryApi.getInventory
    test('debe llamar InventoryApi.getInventory y retornar InventoryResponse',
        () async {
      // Arrange
      final expectedResponse = InventoryResponse(
        productId: testProductId,
        productName: 'Jabón Líquido',
        currentStock: 50.0,
        minStockThreshold: 10.0,
      );
      when(() => mockInventoryApi.getInventory(testProductId))
          .thenAnswer((_) async => expectedResponse);

      // Act
      final result = await repository.getInventory(testProductId);

      // Assert: retorna el mismo InventoryResponse
      expect(result.productId, testProductId);
      expect(result.productName, 'Jabón Líquido');
      expect(result.currentStock, 50.0);

      // Assert: llamó a InventoryApi exactamente una vez
      verify(() => mockInventoryApi.getInventory(testProductId)).called(1);
    });

    // Triangulación: propaga errores desde InventoryApi
    test('debe propagar ApiException cuando InventoryApi.getInventory falla',
        () async {
      // Arrange
      when(() => mockInventoryApi.getInventory(testProductId)).thenThrow(
        const ApiException('Producto no encontrado', 404),
      );

      // Act & Assert
      expect(
        () => repository.getInventory(testProductId),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getLowStock', () {
    // Verifica que getLowStock delega en InventoryApi.getLowStock
    test('debe llamar InventoryApi.getLowStock y retornar lista', () async {
      // Arrange
      final expectedItems = [
        const InventoryResponse(
          productId: 1,
          productName: 'Jabón Líquido',
          currentStock: 5.0,
          minStockThreshold: 10.0,
        ),
        const InventoryResponse(
          productId: 2,
          productName: 'Detergente',
          currentStock: 3.0,
          minStockThreshold: 20.0,
        ),
      ];
      when(() => mockInventoryApi.getLowStock())
          .thenAnswer((_) async => expectedItems);

      // Act
      final result = await repository.getLowStock();

      // Assert: retorna la misma lista
      expect(result, hasLength(2));
      expect(result[0].productId, 1);
      expect(result[0].productName, 'Jabón Líquido');
      expect(result[0].currentStock, 5.0);
      expect(result[1].productId, 2);

      // Assert: llamó a InventoryApi exactamente una vez
      verify(() => mockInventoryApi.getLowStock()).called(1);
    });

    // Triangulación: propaga errores
    test('debe propagar ApiException cuando InventoryApi.getLowStock falla',
        () async {
      // Arrange
      when(() => mockInventoryApi.getLowStock()).thenThrow(
        const ApiException('Error interno', 500),
      );

      // Act & Assert
      expect(
        () => repository.getLowStock(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('adjustStock', () {
    // Verifica que adjustStock delega en InventoryApi.adjustStock
    test('debe llamar InventoryApi.adjustStock y retornar InventoryResponse',
        () async {
      // Arrange
      final request = const AdjustmentRequest(
        type: AdjustmentType.ADJUSTMENT,
        quantity: 10.0,
        reason: 'ajuste manual',
      );
      final expectedResponse = InventoryResponse(
        productId: testProductId,
        productName: 'Jabón Líquido',
        currentStock: 60.0,
        minStockThreshold: 10.0,
      );
      when(() => mockInventoryApi.adjustStock(testProductId, request))
          .thenAnswer((_) async => expectedResponse);

      // Act
      final result = await repository.adjustStock(testProductId, request);

      // Assert: retorna el InventoryResponse correcto
      expect(result.currentStock, 60.0);

      // Assert: llamó con el ID y request correctos
      verify(() => mockInventoryApi.adjustStock(testProductId, request))
          .called(1);
    });

    // Triangulación: propaga errores desde InventoryApi
    test('debe propagar ApiException cuando InventoryApi.adjustStock falla',
        () async {
      // Arrange
      final request = const AdjustmentRequest(
        type: AdjustmentType.BREAKAGE,
        quantity: -5.0,
        reason: 'quebrado',
      );
      when(() => mockInventoryApi.adjustStock(testProductId, request))
          .thenThrow(
        const ApiException('Conflicto de versión', 409),
      );

      // Act & Assert
      expect(
        () => repository.adjustStock(testProductId, request),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
