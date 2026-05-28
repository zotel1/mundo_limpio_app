// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/features/production/data/repositories/bulk_product_repository_impl.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late BulkProductRepositoryImpl repository;

  setUp(() {
    mockDio = MockDio();
    repository = BulkProductRepositoryImpl(mockDio);
  });

  group('BulkProductRepositoryImpl', () {
    test('getBulkProducts debe retornar una lista de BulkProducts', () async {
      // Arrange
      final json = [
        {
          'id': 1,
          'name': 'Alcohol',
          'currentStockLiters': 100.0,
          'costPerLiter': 10.0,
          'conversionRatio': 1.0,
          'active': true,
        },
      ];
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          data: json,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/bulk-products'),
        ),
      );

      // Act
      final result = await repository.getBulkProducts();

      // Assert
      expect(result, isA<List<BulkProduct>>());
      expect(result.first.name, 'Alcohol');
      verify(() => mockDio.get('/api/v1/bulk-products')).called(1);
    });

    test('createBulkProduct debe enviar costPerLiter en el body', () async {
      // Arrange
      final product = BulkProduct(
        id: 0,
        name: 'Nuevo',
        currentStockLiters: 100.0,
        costPerLiter: 12.5,
        conversionRatio: 1.0,
        active: true,
      );
      final json = {
        'id': 1,
        'name': 'Nuevo',
        'currentStockLiters': 100.0,
        'costPerLiter': 12.5,
        'conversionRatio': 1.0,
        'active': true,
      };
      when(() => mockDio.post(any(), data: any(named: "data"))).thenAnswer(
        (_) async => Response(
          data: json,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/bulk-products'),
        ),
      );

      // Act
      final result = await repository.createBulkProduct(product);

      // Assert: verificar que se envió costPerLiter (campo correcto)
      // y que conversionRatio siempre se envía (sin ?? 1.0)
      final captured =
          verify(
                () => mockDio.post(
                  '/api/v1/bulk-products',
                  data: captureAny(named: "data"),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['costPerLiter'], 12.5);
      expect(captured['conversionRatio'], 1.0);
      expect(result.id, 1);
    });
  });
}
