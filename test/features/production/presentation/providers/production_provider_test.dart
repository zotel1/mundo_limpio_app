// TDD: RED — test escrito antes que la implementación
//
// Pruebas unitarias para ProductionProvider.
//
// Verifica:
// - Estado inicial correcto
// - getProductionBatches carga lista y maneja errores
// - createProductionBatch exitoso guarda lastCreatedBatch
// - ChangeNotifier notifica listeners

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/production_provider.dart';

class MockProductionRepository extends Mock implements IProductionRepository {}

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

void main() {
  late MockProductionRepository mockRepo;
  late MockBulkProductRepository mockBulkRepo;
  late ProductionProvider provider;

  setUpAll(() {
    registerFallbackValue(
      ProductionBatchRequest(
        finishedProductId: 0,
        bulkProductId: 0,
        quantityUsed: 0.0,
      ),
    );
    registerFallbackValue(
      ProductionBatch(
        id: 0,
        productId: 0,
        bulkProductId: 0,
        initialQuantity: 0.0,
        currentStock: 0.0,
        unitCostAtProduction: 0.0,
        rawQuantityUsed: 0.0,
        productionDate: DateTime(2026, 1, 1),
      ),
    );
    registerFallbackValue(
      const BulkProduct(
        id: 0,
        name: '',
        currentStockLiters: 0,
        costPerLiter: 0,
        conversionRatio: 1.0,
      ),
    );
  });

  setUp(() {
    mockRepo = MockProductionRepository();
    mockBulkRepo = MockBulkProductRepository();
    provider = ProductionProvider(mockRepo, mockBulkRepo);

    // Stubs por defecto
    when(() => mockRepo.getProductionBatches()).thenAnswer((_) async => []);
    when(() => mockRepo.createProductionBatch(any())).thenAnswer(
      (_) async => ProductionBatch(
        id: 1,
        productId: 1,
        bulkProductId: 1,
        initialQuantity: 10.0,
        currentStock: 8.0,
        unitCostAtProduction: 12.5,
        rawQuantityUsed: 10.0,
        productionDate: DateTime(2026, 5, 18),
      ),
    );
    when(() => mockBulkRepo.getBulkProduct(any())).thenAnswer(
      (_) async => const BulkProduct(
        id: 1,
        name: 'Alcohol',
        currentStockLiters: 100.0,
        costPerLiter: 10.0,
        conversionRatio: 1.0,
      ),
    );
  });

  group('estado inicial', () {
    test('debe iniciar con status initial', () {
      expect(provider.status, ProductionStatus.initial);
    });

    test('debe iniciar sin error', () {
      expect(provider.error, isNull);
    });

    test('isLoading debe ser false al iniciar', () {
      expect(provider.isLoading, isFalse);
    });

    test('debe iniciar con lista vacía', () {
      expect(provider.productionBatches, isEmpty);
    });

    test('lastCreatedBatch debe ser null al iniciar', () {
      expect(provider.lastCreatedBatch, isNull);
    });
  });

  group('getProductionBatches', () {
    test('debe cargar lista y setear status loaded', () async {
      final batches = [
        ProductionBatch(
          id: 1,
          productId: 1,
          bulkProductId: 1,
          initialQuantity: 10.0,
          currentStock: 8.0,
          unitCostAtProduction: 12.5,
          rawQuantityUsed: 10.0,
          productionDate: DateTime(2026, 5, 18),
        ),
      ];
      when(
        () => mockRepo.getProductionBatches(),
      ).thenAnswer((_) async => batches);

      await provider.getProductionBatches();

      expect(provider.status, ProductionStatus.loaded);
      expect(provider.productionBatches, batches);
      expect(provider.isLoading, isFalse);
    });

    test('debe setear error cuando falla', () async {
      when(
        () => mockRepo.getProductionBatches(),
      ).thenThrow(const UnknownApiException('Error de red', 500));

      await provider.getProductionBatches();

      expect(provider.status, ProductionStatus.error);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });
  });

  group('createProductionBatch', () {
    test('debe crear batch exitosamente y guardar lastCreatedBatch', () async {
      final request = ProductionBatchRequest(
        finishedProductId: 1,
        bulkProductId: 1,
        quantityUsed: 10.0,
      );
      final batch = ProductionBatch(
        id: 1,
        productId: 1,
        bulkProductId: 1,
        initialQuantity: 10.0,
        currentStock: 8.0,
        unitCostAtProduction: 12.5,
        rawQuantityUsed: 10.0,
        productionDate: DateTime(2026, 5, 18),
      );
      when(
        () => mockRepo.createProductionBatch(request),
      ).thenAnswer((_) async => batch);

      await provider.createProductionBatch(request);

      expect(provider.status, ProductionStatus.loaded);
      expect(provider.lastCreatedBatch, batch);
      verify(() => mockRepo.createProductionBatch(request)).called(1);
    });

    test('debe setear error cuando falla', () async {
      final request = ProductionBatchRequest(
        finishedProductId: 1,
        bulkProductId: 1,
        quantityUsed: 10.0,
      );
      when(
        () => mockRepo.createProductionBatch(request),
      ).thenThrow(const UnknownApiException('Error al crear batch', 500));

      await provider.createProductionBatch(request);

      expect(provider.status, ProductionStatus.error);
      expect(provider.error, isNotNull);
    });
  });

  group('ChangeNotifier', () {
    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });

    test('debe notificar listeners durante getProductionBatches', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.getProductionBatches();

      expect(notifyCount, greaterThan(0));
    });

    test('debe notificar listeners durante createProductionBatch', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.createProductionBatch(
        ProductionBatchRequest(
          finishedProductId: 1,
          bulkProductId: 1,
          quantityUsed: 10.0,
        ),
      );

      expect(notifyCount, greaterThan(0));
    });
  });
}
