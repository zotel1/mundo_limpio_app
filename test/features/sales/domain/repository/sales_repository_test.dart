// Pruebas unitarias para el contrato abstracto SalesRepository.
//
// Verifica que la interfaz expone los métodos correctos con
// los tipos de retorno esperados, sin depender de implementaciones
// concretas de red o almacenamiento.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo tipos de Dart puro.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';

// Mock del repositorio para verificar el contrato de la interfaz
class MockSalesRepository extends Mock implements SalesRepository {}

void main() {
  late MockSalesRepository mockRepository;

  setUp(() {
    mockRepository = MockSalesRepository();
  });

  group('SalesRepository', () {
    // Verifica que getProducts retorna List<ProductResponse>
    test('getProducts debe retornar List<ProductResponse>', () async {
      // Arrange: stub del método con datos de ejemplo
      final expectedProducts = [
        const ProductResponse(id: 1, name: 'Producto A'),
        const ProductResponse(id: 2, name: 'Producto B'),
      ];
      when(() => mockRepository.getProducts())
          .thenAnswer((_) async => expectedProducts);

      // Act
      final result = await mockRepository.getProducts();

      // Assert
      expect(result, isA<List<ProductResponse>>());
      expect(result, hasLength(2));
      expect(result[0].id, 1);
      expect(result[0].name, 'Producto A');
      expect(result[1].id, 2);
      expect(result[1].name, 'Producto B');
    });

    // Verifica que getBatchesByProduct retorna List<ProductionBatchResponse>
    test('getBatchesByProduct debe retornar List<ProductionBatchResponse>',
        () async {
      // Arrange
      final expectedBatches = [
        const ProductionBatchResponse(
          id: 1,
          productId: 1,
          currentStock: 100.0,
        ),
        const ProductionBatchResponse(
          id: 2,
          productId: 1,
          currentStock: 50.0,
        ),
      ];
      when(() => mockRepository.getBatchesByProduct(1))
          .thenAnswer((_) async => expectedBatches);

      // Act
      final result = await mockRepository.getBatchesByProduct(1);

      // Assert
      expect(result, isA<List<ProductionBatchResponse>>());
      expect(result, hasLength(2));
      expect(result[0].id, 1);
      expect(result[0].currentStock, 100.0);
      expect(result[1].currentStock, 50.0);
    });

    // Verifica que createSale retorna SaleResponse
    test('createSale debe retornar SaleResponse', () async {
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

      when(() => mockRepository.createSale(request))
          .thenAnswer((_) async => expectedResponse);

      // Act
      final result = await mockRepository.createSale(request);

      // Assert
      expect(result, isA<SaleResponse>());
      expect(result.id, 1);
      expect(result.totalAmount, 375.00);
      expect(result.items, hasLength(1));
    });

    // Verifica que se pasa el productId correcto a getBatchesByProduct
    test('getBatchesByProduct debe aceptar productId y delegar', () async {
      // Arrange
      when(() => mockRepository.getBatchesByProduct(42))
          .thenAnswer((_) async => []);

      // Act
      await mockRepository.getBatchesByProduct(42);

      // Assert
      verify(() => mockRepository.getBatchesByProduct(42)).called(1);
    });

    // Verifica que createSale recibe el SaleRequest correcto
    test('createSale debe recibir SaleRequest y delegar', () async {
      // Arrange
      final request = SaleRequest(productId: 5, quantity: 10.0);
      when(() => mockRepository.createSale(request))
          .thenAnswer((_) async => SaleResponse(
                id: 2,
                totalAmount: 100.0,
                createdAt: DateTime(2026, 5, 10),
                items: [],
              ));

      // Act
      await mockRepository.createSale(request);

      // Assert
      verify(() => mockRepository.createSale(request)).called(1);
    });
  });
}
