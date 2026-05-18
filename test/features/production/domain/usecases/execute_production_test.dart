// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/usecases/execute_production.dart';

class MockProductionRepository extends Mock implements IProductionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ProductionBatchRequest(
        finishedProductId: 0,
        bulkProductId: 0,
        quantityUsed: 0.0,
      ),
    );
  });

  late MockProductionRepository mockRepository;
  late ExecuteProduction executeProduction;

  setUp(() {
    mockRepository = MockProductionRepository();
    executeProduction = ExecuteProduction(mockRepository);
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
  });
}
