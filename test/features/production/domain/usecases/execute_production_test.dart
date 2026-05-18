// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/usecases/execute_production.dart';

class MockProductionRepository extends Mock implements IProductionRepository {}

class MockBulkProductRepository extends Mock implements IBulkProductRepository {}

// TDD: RED — test escrito antes que la implementación
// TDD: GREEN — implementación mínima para pasar el test

void main() {
  setUpAll(() {
    registerFallbackValue(
      ProductionBatchRequest(
        finishedProductId: 0,
        bulkProductId: 0,
        quantityUsed: 0.0,
      ),
    );
    registerFallbackValue(
      const BulkProduct(id: 0, name: '', unitOfMeasure: '', stock: 0.0),
    );
  });

  late MockProductionRepository mockRepository;
  late MockBulkProductRepository mockBulkRepo;
  late ExecuteProduction executeProduction;

  setUp(() {
    mockRepository = MockProductionRepository();
    mockBulkRepo = MockBulkProductRepository();
    executeProduction = ExecuteProduction(mockRepository, mockBulkRepo);

    // Stub por defecto: stock suficiente
    when(() => mockBulkRepo.getBulkProduct(any())).thenAnswer(
      (_) async => const BulkProduct(id: 1, name: 'Alcohol', unitOfMeasure: 'L', stock: 100.0),
    );
  });

  group('ExecuteProduction Use Case', () {
    test('debe ejecutar la producción y retornar un ProductionBatch', () async {
      // Arrange
      final request = ProductionBatchRequest(
        finishedProductId: 10,
        bulkProductId: 20,
        quantityUsed: 5.0,
      );
      final productionBatch = ProductionBatch(
        id: 1,
        finishedProductId: 10,
        bulkProductId: 20,
        quantityUsed: 5.0,
        quantityProduced: 4.0,
        date: DateTime.now(),
      );
      when(() => mockRepository.createProductionBatch(any())).thenAnswer((_) async => productionBatch);

      // Act
      final result = await executeProduction.execute(request);

      // Assert
      expect(result, productionBatch);
      verify(() => mockRepository.createProductionBatch(request)).called(1);
    });

    test(
      'debe lanzar Exception cuando finishedProductId es 0',
      () async {
        final request = ProductionBatchRequest(
          finishedProductId: 0,
          bulkProductId: 20,
          quantityUsed: 5.0,
        );

        await expectLater(
          executeProduction.execute(request),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => mockRepository.createProductionBatch(any()));
      },
    );

    test(
      'debe lanzar Exception cuando bulkProductId es 0',
      () async {
        final request = ProductionBatchRequest(
          finishedProductId: 10,
          bulkProductId: 0,
          quantityUsed: 5.0,
        );

        await expectLater(
          executeProduction.execute(request),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => mockRepository.createProductionBatch(any()));
      },
    );

    test(
      'debe lanzar Exception cuando quantityUsed es 0',
      () async {
        final request = ProductionBatchRequest(
          finishedProductId: 10,
          bulkProductId: 20,
          quantityUsed: 0,
        );

        await expectLater(
          executeProduction.execute(request),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => mockRepository.createProductionBatch(any()));
      },
    );

    test(
      'debe lanzar Exception cuando quantityUsed es negativo',
      () async {
        final request = ProductionBatchRequest(
          finishedProductId: 10,
          bulkProductId: 20,
          quantityUsed: -1,
        );

        await expectLater(
          executeProduction.execute(request),
          throwsA(isA<Exception>()),
        );
        verifyNever(() => mockRepository.createProductionBatch(any()));
      },
    );

    // TDD: RED — test escrito antes que la implementación
    test(
      'debe lanzar error si el stock de materia prima es insuficiente',
      () async {
        // Arrange
        final request = ProductionBatchRequest(
          finishedProductId: 10,
          bulkProductId: 20,
          quantityUsed: 5.0,
        );
        when(() => mockBulkRepo.getBulkProduct(20)).thenAnswer(
          (_) async => const BulkProduct(id: 20, name: 'Alcohol', unitOfMeasure: 'L', stock: 2.0),
        );

        // Act & Assert
        await expectLater(
          executeProduction.execute(request),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Stock insuficiente'),
            ),
          ),
        );
        verifyNever(() => mockRepository.createProductionBatch(any()));
      },
    );
  });
}
