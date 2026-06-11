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

import 'package:mundo_limpio_app/features/sales/domain/entities/batch_info.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/create_sale_data.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/product_info.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/sale.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/sale_item.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';

// Mock del repositorio para verificar el contrato de la interfaz
class MockSalesRepository extends Mock implements SalesRepository {}

void main() {
  late MockSalesRepository mockRepository;

  setUp(() {
    mockRepository = MockSalesRepository();
  });

  group('SalesRepository', () {
    // Verifica que getProducts retorna List<ProductInfo>
    test('getProducts debe retornar List<ProductInfo>', () async {
      // Arrange: stub del método con datos de ejemplo
      final expectedProducts = [
        const ProductInfo(id: 1, name: 'Producto A'),
        const ProductInfo(id: 2, name: 'Producto B'),
      ];
      when(
        () => mockRepository.getProducts(),
      ).thenAnswer((_) async => expectedProducts);

      // Act
      final result = await mockRepository.getProducts();

      // Assert
      expect(result, isA<List<ProductInfo>>());
      expect(result, hasLength(2));
      expect(result[0].id, 1);
      expect(result[0].name, 'Producto A');
      expect(result[1].id, 2);
      expect(result[1].name, 'Producto B');
    });

    // Verifica que getBatchesByProduct retorna List<BatchInfo>
    test('getBatchesByProduct debe retornar List<BatchInfo>', () async {
      // Arrange
      final expectedBatches = [
        const BatchInfo(id: 1, productId: 1, quantity: 100.0),
        const BatchInfo(id: 2, productId: 1, quantity: 50.0),
      ];
      when(
        () => mockRepository.getBatchesByProduct(1),
      ).thenAnswer((_) async => expectedBatches);

      // Act
      final result = await mockRepository.getBatchesByProduct(1);

      // Assert
      expect(result, isA<List<BatchInfo>>());
      expect(result, hasLength(2));
      expect(result[0].id, 1);
      expect(result[0].quantity, 100.0);
      expect(result[1].quantity, 50.0);
    });

    // Verifica que createSale retorna Sale
    test('createSale debe retornar Sale', () async {
      // Arrange
      final data = CreateSaleData(productId: 1, quantity: 30.0);
      final expectedResponse = Sale(
        id: 1,
        total: 375.00,
        createdAt: DateTime(2026, 5, 10, 10, 30, 0),
        items: const [
          SaleItem(
            productId: 1,
            productName: 'Test Product',
            quantity: 30.0,
            unitPrice: 150.00,
          ),
        ],
        status: 'completed',
      );

      when(
        () => mockRepository.createSale(data),
      ).thenAnswer((_) async => expectedResponse);

      // Act
      final result = await mockRepository.createSale(data);

      // Assert
      expect(result, isA<Sale>());
      expect(result.id, 1);
      expect(result.total, 375.00);
      expect(result.items, hasLength(1));
    });

    // Verifica que se pasa el productId correcto a getBatchesByProduct
    test('getBatchesByProduct debe aceptar productId y delegar', () async {
      // Arrange
      when(
        () => mockRepository.getBatchesByProduct(42),
      ).thenAnswer((_) async => []);

      // Act
      await mockRepository.getBatchesByProduct(42);

      // Assert
      verify(() => mockRepository.getBatchesByProduct(42)).called(1);
    });

    // Verifica que createSale recibe el CreateSaleData correcto
    test('createSale debe recibir CreateSaleData y delegar', () async {
      // Arrange
      final data = CreateSaleData(productId: 5, quantity: 10.0);
      when(() => mockRepository.createSale(data)).thenAnswer(
        (_) async => Sale(
          id: 2,
          total: 100.0,
          createdAt: DateTime(2026, 5, 10),
          items: [],
          status: 'completed',
        ),
      );

      // Act
      await mockRepository.createSale(data);

      // Assert
      verify(() => mockRepository.createSale(data)).called(1);
    });
  });
}
