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
        {'id': 1, 'name': 'Alcohol', 'unit_of_measure': 'L', 'stock': 10.0},
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

    test('createBulkProduct debe retornar el BulkProduct creado', () async {
      // Arrange
      final product = BulkProduct(
        id: 0,
        name: 'Nuevo',
        unitOfMeasure: 'L',
        stock: 0.0,
      );
      final json = {
        'id': 1,
        'name': 'Nuevo',
        'unit_of_measure': 'L',
        'stock': 0.0,
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

      // Assert
      expect(result.id, 1);
      verify(
        () => mockDio.post('/api/v1/bulk-products', data: any(named: "data")),
      ).called(1);
    });
  });
}
