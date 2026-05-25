// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/products/data/api/products_api.dart';
import 'package:mundo_limpio_app/features/products/data/models/product_model.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProductsApi api;

  setUp(() {
    mockDio = MockDio();
    api = ProductsApi(dio: mockDio);
  });

  group('ProductsApi', () {
    group('getProducts (list active)', () {
      test(
        'debe retornar lista de ProductModel en GET /api/v1/products',
        () async {
          // Arrange
          final json = [
            {
              'id': 1,
              'sku': 'PROD-001',
              'name': 'Jabón',
              'min_price': 150.0,
              'active': true,
            },
          ];
          when(() => mockDio.get('/api/v1/products')).thenAnswer(
            (_) async => Response(
              data: json,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/products'),
            ),
          );

          // Act
          final result = await api.getProducts();

          // Assert
          expect(result, isA<List<ProductModel>>());
          expect(result, hasLength(1));
          expect(result.first.name, 'Jabón');
          verify(() => mockDio.get('/api/v1/products')).called(1);
        },
      );

      test('debe lanzar ApiException cuando Dio falla', () async {
        // Arrange
        when(() => mockDio.get('/api/v1/products')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products'),
            response: Response(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/products'),
            ),
          ),
        );

        // Act & Assert
        expect(
          () async => await api.getProducts(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getAllProducts (list all)', () {
      test(
        'debe retornar lista de ProductModel en GET /api/v1/products/all',
        () async {
          // Arrange
          final json = [
            {
              'id': 1,
              'sku': 'PROD-001',
              'name': 'Jabón',
              'min_price': 150.0,
              'active': true,
            },
            {
              'id': 2,
              'sku': 'PROD-002',
              'name': 'Detergente',
              'min_price': null,
              'active': false,
            },
          ];
          when(() => mockDio.get('/api/v1/products/all')).thenAnswer(
            (_) async => Response(
              data: json,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/products/all'),
            ),
          );

          // Act
          final result = await api.getAllProducts();

          // Assert
          expect(result, hasLength(2));
          expect(result[1].active, false);
          verify(() => mockDio.get('/api/v1/products/all')).called(1);
        },
      );

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(() => mockDio.get('/api/v1/products/all')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products/all'),
            response: Response(
              data: null,
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/products/all'),
            ),
          ),
        );

        expect(
          () async => await api.getAllProducts(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getProductById', () {
      test('debe retornar ProductModel en GET /api/v1/products/{id}', () async {
        // Arrange
        final json = {
          'id': 1,
          'sku': 'PROD-001',
          'name': 'Jabón',
          'min_price': 150.0,
          'active': true,
        };
        when(() => mockDio.get('/api/v1/products/1')).thenAnswer(
          (_) async => Response(
            data: json,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/products/1'),
          ),
        );

        // Act
        final result = await api.getProductById(1);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.id, 1);
        verify(() => mockDio.get('/api/v1/products/1')).called(1);
      });

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(() => mockDio.get('/api/v1/products/1')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products/1'),
            response: Response(
              data: null,
              statusCode: 404,
              requestOptions: RequestOptions(path: '/api/v1/products/1'),
            ),
          ),
        );

        expect(
          () async => await api.getProductById(1),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getProductBySku', () {
      test(
        'debe retornar ProductModel en GET /api/v1/products/sku/{sku}',
        () async {
          // Arrange
          final json = {
            'id': 1,
            'sku': 'PROD-001',
            'name': 'Jabón',
            'min_price': 150.0,
            'active': true,
          };
          when(() => mockDio.get('/api/v1/products/sku/PROD-001')).thenAnswer(
            (_) async => Response(
              data: json,
              statusCode: 200,
              requestOptions: RequestOptions(
                path: '/api/v1/products/sku/PROD-001',
              ),
            ),
          );

          // Act
          final result = await api.getProductBySku('PROD-001');

          // Assert
          expect(result, isA<ProductModel>());
          expect(result.sku, 'PROD-001');
          verify(() => mockDio.get('/api/v1/products/sku/PROD-001')).called(1);
        },
      );

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(() => mockDio.get('/api/v1/products/sku/PROD-001')).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/products/sku/PROD-001',
            ),
            response: Response(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(
                path: '/api/v1/products/sku/PROD-001',
              ),
            ),
          ),
        );

        expect(
          () async => await api.getProductBySku('PROD-001'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('createProduct', () {
      test('debe retornar ProductModel en POST /api/v1/products', () async {
        // Arrange
        final requestJson = {
          'sku': 'PROD-NEW',
          'name': 'Nuevo',
          'min_price': 100.0,
          'active': true,
        };
        final responseJson = {
          'id': 1,
          'sku': 'PROD-NEW',
          'name': 'Nuevo',
          'min_price': 100.0,
          'active': true,
        };
        when(
          () => mockDio.post('/api/v1/products', data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            data: responseJson,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/api/v1/products'),
          ),
        );

        // Act
        final result = await api.createProduct(requestJson);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.id, 1);
        verify(
          () => mockDio.post('/api/v1/products', data: any(named: 'data')),
        ).called(1);
      });

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(
          () => mockDio.post('/api/v1/products', data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products'),
            response: Response(
              data: null,
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/products'),
            ),
          ),
        );

        expect(
          () async => await api.createProduct({}),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('updateProduct', () {
      test('debe retornar ProductModel en PUT /api/v1/products/{id}', () async {
        // Arrange
        final requestJson = {
          'sku': 'PROD-001',
          'name': 'Jabón Modificado',
          'min_price': 200.0,
          'active': true,
        };
        final responseJson = {
          'id': 1,
          'sku': 'PROD-001',
          'name': 'Jabón Modificado',
          'min_price': 200.0,
          'active': true,
        };
        when(
          () => mockDio.put('/api/v1/products/1', data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response(
            data: responseJson,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/products/1'),
          ),
        );

        // Act
        final result = await api.updateProduct(1, requestJson);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.name, 'Jabón Modificado');
        verify(
          () => mockDio.put('/api/v1/products/1', data: any(named: 'data')),
        ).called(1);
      });

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(
          () => mockDio.put('/api/v1/products/1', data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products/1'),
            response: Response(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/products/1'),
            ),
          ),
        );

        expect(
          () async => await api.updateProduct(1, {}),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('deleteProduct', () {
      test('debe completar en DELETE /api/v1/products/{id}', () async {
        // Arrange
        when(() => mockDio.delete('/api/v1/products/1')).thenAnswer(
          (_) async => Response(
            data: null,
            statusCode: 204,
            requestOptions: RequestOptions(path: '/api/v1/products/1'),
          ),
        );

        // Act
        await api.deleteProduct(1);

        // Assert
        verify(() => mockDio.delete('/api/v1/products/1')).called(1);
      });

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(() => mockDio.delete('/api/v1/products/1')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products/1'),
            response: Response(
              data: null,
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/products/1'),
            ),
          ),
        );

        expect(
          () async => await api.deleteProduct(1),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('reactivateProduct', () {
      test(
        'debe retornar ProductModel en PATCH /api/v1/products/{id}/reactivate',
        () async {
          // Arrange
          final json = {
            'id': 1,
            'sku': 'PROD-001',
            'name': 'Jabón',
            'min_price': 150.0,
            'active': true,
          };
          when(() => mockDio.patch('/api/v1/products/1/reactivate')).thenAnswer(
            (_) async => Response(
              data: json,
              statusCode: 200,
              requestOptions: RequestOptions(
                path: '/api/v1/products/1/reactivate',
              ),
            ),
          );

          // Act
          final result = await api.reactivateProduct(1);

          // Assert
          expect(result, isA<ProductModel>());
          expect(result.active, true);
          verify(
            () => mockDio.patch('/api/v1/products/1/reactivate'),
          ).called(1);
        },
      );

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(() => mockDio.patch('/api/v1/products/1/reactivate')).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/products/1/reactivate',
            ),
            response: Response(
              data: null,
              statusCode: 404,
              requestOptions: RequestOptions(
                path: '/api/v1/products/1/reactivate',
              ),
            ),
          ),
        );

        expect(
          () async => await api.reactivateProduct(1),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}
