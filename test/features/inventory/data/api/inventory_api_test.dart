// Pruebas unitarias para InventoryApi.
// Verifica que las llamadas HTTP a los endpoints de inventario
// se hacen correctamente y que los errores HTTP se convierten
// a ApiException con el subtipo correcto.
//
// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';

// Mock de Dio para aislar las pruebas HTTP de la red real
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late InventoryApi inventoryApi;

  const testProductId = 1;

  setUp(() {
    mockDio = MockDio();
    inventoryApi = InventoryApi(dio: mockDio);
  });

  group('getInventory', () {
    // Escenario feliz: GET /api/v1/inventory/{id} retorna 200 con InventoryResponse
    test('debe GET /api/v1/inventory/{productId} y retornar InventoryResponse en 200',
        () async {
      // Arrange: respuesta simulada del backend
      final responseData = {
        'productId': testProductId,
        'productName': 'Jabón Líquido',
        'currentStock': 50.0,
        'minStockThreshold': 10.0,
      };
      final response = Response(
        requestOptions: RequestOptions(
          path: '/api/v1/inventory/$testProductId',
        ),
        data: responseData,
        statusCode: 200,
      );

      when(() => mockDio.get(
            '/api/v1/inventory/$testProductId',
          )).thenAnswer((_) async => response);

      // Act
      final result = await inventoryApi.getInventory(testProductId);

      // Assert: verifica que el InventoryResponse tiene los campos correctos
      expect(result.productId, testProductId);
      expect(result.productName, 'Jabón Líquido');
      expect(result.currentStock, 50.0);
      expect(result.minStockThreshold, 10.0);

      // Verifica que se llamó al endpoint correcto
      verify(() => mockDio.get(
            '/api/v1/inventory/$testProductId',
          )).called(1);
    });

    // Error 404: debe lanzar ApiException
    test('debe lanzar ApiException en getInventory con not found (404)',
        () async {
      // Arrange: simula 404 Not Found
      when(() => mockDio.get(
            '/api/v1/inventory/$testProductId',
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/api/v1/inventory/$testProductId',
          ),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(
              path: '/api/v1/inventory/$testProductId',
            ),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => inventoryApi.getInventory(testProductId),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getLowStock', () {
    // Escenario feliz: GET /api/v1/inventory/low-stock retorna 200 con lista
    test('debe GET /api/v1/inventory/low-stock y retornar lista en 200',
        () async {
      // Arrange: respuesta simulada del backend
      final responseData = [
        {
          'productId': 1,
          'productName': 'Jabón Líquido',
          'currentStock': 5.0,
          'minStockThreshold': 10.0,
        },
        {
          'productId': 2,
          'productName': 'Detergente',
          'currentStock': 3.0,
          'minStockThreshold': 20.0,
        },
      ];
      final response = Response(
        requestOptions: RequestOptions(
          path: '/api/v1/inventory/low-stock',
        ),
        data: responseData,
        statusCode: 200,
      );

      when(() => mockDio.get(
            '/api/v1/inventory/low-stock',
          )).thenAnswer((_) async => response);

      // Act
      final result = await inventoryApi.getLowStock();

      // Assert: verifica la lista de productos con bajo stock
      expect(result, hasLength(2));
      expect(result[0].productId, 1);
      expect(result[0].productName, 'Jabón Líquido');
      expect(result[0].currentStock, 5.0);
      expect(result[0].minStockThreshold, 10.0);
      expect(result[1].productId, 2);

      // Verifica que se llamó al endpoint correcto
      verify(() => mockDio.get(
            '/api/v1/inventory/low-stock',
          )).called(1);
    });
  });

  group('adjustStock', () {
    // Escenario feliz: POST /api/v1/inventory/{id}/adjust retorna 200
    test('debe POST /api/v1/inventory/{productId}/adjust y retornar InventoryResponse en 200',
        () async {
      // Arrange
      final request = const AdjustmentRequest(
        type: AdjustmentType.ADJUSTMENT,
        quantity: 10.0,
        reason: 'ajuste manual',
      );
      final responseData = {
        'productId': testProductId,
        'productName': 'Jabón Líquido',
        'currentStock': 60.0,
        'minStockThreshold': 10.0,
      };
      final response = Response(
        requestOptions: RequestOptions(
          path: '/api/v1/inventory/$testProductId/adjust',
        ),
        data: responseData,
        statusCode: 200,
      );

      when(() => mockDio.post(
            '/api/v1/inventory/$testProductId/adjust',
            data: any(named: 'data'),
          )).thenAnswer((_) async => response);

      // Act
      final result = await inventoryApi.adjustStock(testProductId, request);

      // Assert
      expect(result.currentStock, 60.0);

      verify(() => mockDio.post(
            '/api/v1/inventory/$testProductId/adjust',
            data: {
              'type': 'ADJUSTMENT',
              'quantity': 10.0,
              'reason': 'ajuste manual',
            },
          )).called(1);
    });

    // Error 400: debe lanzar ApiException
    test('debe lanzar ApiException en adjustStock con bad request (400)',
        () async {
      // Arrange
      when(() => mockDio.post(
            '/api/v1/inventory/$testProductId/adjust',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/api/v1/inventory/$testProductId/adjust',
          ),
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(
              path: '/api/v1/inventory/$testProductId/adjust',
            ),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => inventoryApi.adjustStock(
          testProductId,
          const AdjustmentRequest(
            type: AdjustmentType.ADJUSTMENT,
            quantity: -100.0,
            reason: 'cantidad inválida',
          ),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    // Error 409: debe lanzar ApiException
    test('debe lanzar ApiException en adjustStock con conflict (409)',
        () async {
      // Arrange
      when(() => mockDio.post(
            '/api/v1/inventory/$testProductId/adjust',
            data: any(named: 'data'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/api/v1/inventory/$testProductId/adjust',
          ),
          response: Response(
            statusCode: 409,
            requestOptions: RequestOptions(
              path: '/api/v1/inventory/$testProductId/adjust',
            ),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => inventoryApi.adjustStock(
          testProductId,
          const AdjustmentRequest(
            type: AdjustmentType.ADJUSTMENT,
            quantity: 5.0,
            reason: 'conflicto de versión',
          ),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
