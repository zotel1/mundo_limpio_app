// TDD: RED — test escrito para verificar comportamiento existente
//
// Pruebas de integración para ProductionRepositoryImpl.
//
// Verifica que el repositorio:
// - Interactúa correctamente con Dio (URLs, métodos HTTP, body)
// - Mapea correctamente DTO → Entity

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/production/data/repositories/production_repository_impl.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProductionRepositoryImpl repository;

  setUp(() {
    mockDio = MockDio();
    repository = ProductionRepositoryImpl(mockDio);
  });

  group('ProductionRepositoryImpl', () {
    test(
      'getProductionBatches debe retornar una lista de ProductionBatches',
      () async {
        // Arrange
        final json = {
          'content': [
            {
              'id': 1,
              'productId': 10,
              'productName': 'Jabón Líquido',
              'bulkProductId': 20,
              'bulkProductName': 'Alcohol',
              'initialQuantity': 100.0,
              'currentStock': 85.0,
              'unitCostAtProduction': 12.5,
              'rawQuantityUsed': 15.0,
              'productionDate': '2026-05-18T10:00:00Z',
            },
            {
              'id': 2,
              'productId': 11,
              'productName': 'Detergente',
              'bulkProductId': 21,
              'bulkProductName': 'Esencia',
              'initialQuantity': 50.0,
              'currentStock': 40.0,
              'unitCostAtProduction': 10.0,
              'rawQuantityUsed': 10.0,
              'productionDate': '2026-05-18T11:00:00Z',
            },
          ],
        };
        when(() => mockDio.get(any())).thenAnswer(
          (_) async => Response(
            data: json,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/production-batches'),
          ),
        );

        // Act
        final result = await repository.getProductionBatches();

        // Assert
        expect(result, isA<List<ProductionBatch>>());
        expect(result.length, 2);
        expect(result.first.id, 1);
        expect(result.first.productId, 10);
        expect(result.first.productName, 'Jabón Líquido');
        expect(result.first.bulkProductId, 20);
        expect(result.first.bulkProductName, 'Alcohol');
        expect(result.first.initialQuantity, 100.0);
        expect(result.first.rawQuantityUsed, 15.0);
        expect(result.last.id, 2);
        verify(() => mockDio.get('/api/v1/production-batches')).called(1);
      },
    );

    test(
      'getProductionBatches debe lanzar Exception cuando Dio falla',
      () async {
        // Arrange
        when(() => mockDio.get(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/production-batches'),
          ),
        );

        // Act
        final call = repository.getProductionBatches();

        // Assert
        await expectLater(call, throwsA(isA<Exception>()));
      },
    );

    test(
      'getProductionBatch debe retornar un ProductionBatch por ID',
      () async {
        // Arrange
        final json = {
          'id': 1,
          'productId': 10,
          'productName': 'Jabón Líquido',
          'bulkProductId': 20,
          'bulkProductName': 'Alcohol',
          'initialQuantity': 100.0,
          'currentStock': 85.0,
          'unitCostAtProduction': 12.5,
          'rawQuantityUsed': 15.0,
          'productionDate': '2026-05-18T10:00:00Z',
        };
        when(() => mockDio.get(any())).thenAnswer(
          (_) async => Response(
            data: json,
            statusCode: 200,
            requestOptions: RequestOptions(
              path: '/api/v1/production-batches/1',
            ),
          ),
        );

        // Act
        final result = await repository.getProductionBatch(1);

        // Assert
        expect(result, isA<ProductionBatch>());
        expect(result.id, 1);
        expect(result.productId, 10);
        expect(result.bulkProductId, 20);
        expect(result.initialQuantity, 100.0);
        expect(result.rawQuantityUsed, 15.0);
        verify(() => mockDio.get('/api/v1/production-batches/1')).called(1);
      },
    );

    test(
      'createProductionBatch debe retornar el ProductionBatch creado',
      () async {
        // Arrange
        final request = ProductionBatchRequest(
          finishedProductId: 10,
          bulkProductId: 20,
          quantityUsed: 5.0,
        );
        final responseJson = {
          'id': 1,
          'productId': 10,
          'initialQuantity': 100.0,
          'currentStock': 85.0,
          'unitCostAtProduction': 12.5,
          'rawQuantityUsed': 15.0,
          'productionDate': '2026-05-18T10:00:00Z',
        };
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: responseJson,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/api/v1/production-batches'),
          ),
        );

        // Act
        final result = await repository.createProductionBatch(request);

        // Assert
        expect(result, isA<ProductionBatch>());
        expect(result.id, 1);
        expect(result.productId, 10);
        expect(result.initialQuantity, 100.0);
        verify(
          () => mockDio.post(
            '/api/v1/production-batches',
            data: {
              'productId': 10,
              'bulkProductId': 20,
              'rawQuantityUsed': 5.0,
            },
          ),
        ).called(1);
      },
    );
  });
}
