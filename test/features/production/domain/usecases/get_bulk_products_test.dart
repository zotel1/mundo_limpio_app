// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/usecases/get_bulk_products.dart';

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

void main() {
  late MockBulkProductRepository mockRepository;
  late GetBulkProducts getBulkProducts;

  setUp(() {
    mockRepository = MockBulkProductRepository();
    getBulkProducts = GetBulkProducts(mockRepository);
  });

  group('GetBulkProducts Use Case', () {
    test(
      'debe retornar una lista de BulkProducts cuando el repositorio tiene datos',
      () async {
        // Arrange
        final bulkProducts = [
          BulkProduct(id: 1, name: 'Alcohol', unitOfMeasure: 'L', stock: 10.0),
          BulkProduct(id: 2, name: 'Agua', unitOfMeasure: 'L', stock: 20.0),
        ];
        when(
          () => mockRepository.getBulkProducts(),
        ).thenAnswer((_) async => bulkProducts);

        // Act
        final result = await getBulkProducts.execute();

        // Assert
        expect(result, bulkProducts);
        verify(() => mockRepository.getBulkProducts()).called(1);
      },
    );

    test(
      'debe retornar una lista vacía cuando el repositorio no tiene datos',
      () async {
        // Arrange
        when(
          () => mockRepository.getBulkProducts(),
        ).thenAnswer((_) async => []);

        // Act
        final result = await getBulkProducts.execute();

        // Assert
        expect(result, isEmpty);
        verify(() => mockRepository.getBulkProducts()).called(1);
      },
    );
  });
}
