// Pruebas unitarias para SalesRepositoryImpl.
// Verifica que el repositorio delega correctamente en SalesApi:
// - getProducts: llama SalesApi.getProducts → retorna lista
// - getBatchesByProduct: llama SalesApi.getBatchesByProduct con el ID correcto
// - createSale: llama SalesApi.createSale → retorna SaleResponse
// - Errores: propaga ApiException desde SalesApi
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/data/api/sales_api.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/data/repository/sales_repository_impl.dart';

// Mock de SalesApi para aislar las pruebas del repositorio de la red real
class MockSalesApi extends Mock implements SalesApi {}

void main() {
  late MockSalesApi mockSalesApi;
  late SalesRepositoryImpl repository;

  setUp(() {
    mockSalesApi = MockSalesApi();
    repository = SalesRepositoryImpl(salesApi: mockSalesApi);
  });

  group('getProducts', () {
    // Verifica que getProducts delega en SalesApi.getProducts
    test('debe llamar SalesApi.getProducts y retornar lista de productos',
        () async {
      // Arrange
      final expectedProducts = [
        const ProductResponse(id: 1, name: 'Producto A'),
        const ProductResponse(id: 2, name: 'Producto B'),
      ];
      when(() => mockSalesApi.getProducts())
          .thenAnswer((_) async => expectedProducts);

      // Act
      final result = await repository.getProducts();

      // Assert: retorna los mismos productos
      expect(result, hasLength(2));
      expect(result[0].id, 1);
      expect(result[0].name, 'Producto A');
      expect(result[1].id, 2);

      // Assert: llamó a SalesApi exactamente una vez
      verify(() => mockSalesApi.getProducts()).called(1);
    });

    // Triangulación: propaga errores desde SalesApi
    test('debe propagar ApiException cuando SalesApi.getProducts falla',
        () async {
      // Arrange
      when(() => mockSalesApi.getProducts()).thenThrow(
        const ApiException('Error de red', 0),
      );

      // Act & Assert
      expect(
        () => repository.getProducts(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getBatchesByProduct', () {
    // Verifica que getBatchesByProduct pasa el productId correcto
    test('debe llamar SalesApi.getBatchesByProduct con el productId correcto',
        () async {
      // Arrange
      const productId = 42;
      final expectedBatches = [
        const ProductionBatchResponse(
          id: 1,
          productId: productId,
          currentStock: 100.0,
        ),
      ];
      when(() => mockSalesApi.getBatchesByProduct(productId))
          .thenAnswer((_) async => expectedBatches);

      // Act
      final result = await repository.getBatchesByProduct(productId);

      // Assert: retorna los lotes correctos
      expect(result, hasLength(1));
      expect(result[0].id, 1);
      expect(result[0].productId, productId);

      // Assert: llamó con el ID correcto
      verify(() => mockSalesApi.getBatchesByProduct(productId)).called(1);
    });

    // Triangulación: propaga errores
    test('debe propagar ApiException cuando SalesApi.getBatchesByProduct falla',
        () async {
      // Arrange
      when(() => mockSalesApi.getBatchesByProduct(any())).thenThrow(
        const ApiException('Producto no encontrado', 404),
      );

      // Act & Assert
      expect(
        () => repository.getBatchesByProduct(1),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('createSale', () {
    // Verifica que createSale delega en SalesApi.createSale
    test('debe llamar SalesApi.createSale y retornar SaleResponse', () async {
      // Arrange
      final request = SaleRequest(productId: 1, quantity: 30.0);
      final expectedResponse = SaleResponse(
        id: 1,
        totalAmount: 375.00,
        createdAt: DateTime(2026, 5, 10, 10, 30, 0),
        items: const [
          SaleItemResponse(
            batchId: 42,
            quantity: 30.0,
            unitPrice: 150.00,
            unitCost: 100.00,
          ),
        ],
      );
      when(() => mockSalesApi.createSale(request))
          .thenAnswer((_) async => expectedResponse);

      // Act
      final result = await repository.createSale(request);

      // Assert: retorna el SaleResponse correcto
      expect(result.id, 1);
      expect(result.totalAmount, 375.00);
      expect(result.items, hasLength(1));

      // Assert: llamó con el request correcto
      verify(() => mockSalesApi.createSale(request)).called(1);
    });

    // Triangulación: propaga errores desde SalesApi
    test('debe propagar ApiException cuando SalesApi.createSale falla',
        () async {
      // Arrange
      final request = SaleRequest(productId: 1, quantity: 100.0);
      when(() => mockSalesApi.createSale(request)).thenThrow(
        const ApiException('Stock insuficiente', 400),
      );

      // Act & Assert
      expect(
        () => repository.createSale(request),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
