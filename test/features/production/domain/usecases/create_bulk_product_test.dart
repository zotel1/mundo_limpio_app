// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/usecases/create_bulk_product.dart';

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const BulkProduct(
        id: 0,
        name: '',
        currentStockLiters: 0,
        costPerLiter: 0,
      ),
    );
  });

  late MockBulkProductRepository mockRepository;
  late CreateBulkProduct createBulkProduct;

  setUp(() {
    mockRepository = MockBulkProductRepository();
    createBulkProduct = CreateBulkProduct(mockRepository);
  });

  group('CreateBulkProduct Use Case', () {
    test('debe crear un BulkProduct correctamente', () async {
      // Arrange
      final bulkProduct = BulkProduct(
        id: 1,
        name: 'Alcohol',
        currentStockLiters: 10.0,
        costPerLiter: 5.0,
      );
      when(
        () => mockRepository.createBulkProduct(any()),
      ).thenAnswer((_) async => bulkProduct);

      // Act
      final result = await createBulkProduct.execute(bulkProduct);

      // Assert
      expect(result, bulkProduct);
      verify(() => mockRepository.createBulkProduct(bulkProduct)).called(1);
    });
  });
}
