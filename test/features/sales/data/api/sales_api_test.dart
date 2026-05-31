// Pruebas unitarias para SalesApi.
// Verifica que las llamadas HTTP a los endpoints de ventas,
// productos y lotes se hacen correctamente y que los errores
// HTTP se convierten a ApiException con el subtipo correcto.
//
// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/data/api/sales_api.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';

// Mock de Dio para aislar las pruebas HTTP de la red real
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SalesApi salesApi;

  // Constantes para evitar magic strings
  const testProductId = 1;
  const testQuantity = 30.0;
  const testBatchId = 42;

  setUp(() {
    mockDio = MockDio();
    salesApi = SalesApi(dio: mockDio);
  });

  group('createSale', () {
    // Escenario feliz: POST /api/v1/sales retorna 201 con SaleResponse
    test('debe POST /api/v1/sales y retornar SaleResponse en 201', () async {
      // Arrange: respuesta simulada del backend
      final responseData = {
        'id': 1,
        'totalAmount': 375.00,
        'createdAt': '2026-05-10T10:30:00.000',
        'items': [
          {
            'batchId': testBatchId,
            'productId': testProductId,
            'productName': 'Lavandina 3L',
            'quantity': testQuantity,
            'unitPrice': 150.00,
            'unitCost': 100.00,
          },
        ],
      };
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/sales'),
        data: responseData,
        statusCode: 201,
      );

      when(
        () => mockDio.post('/api/v1/sales', data: any(named: 'data')),
      ).thenAnswer((_) async => response);

      final request = SaleRequest(
        productId: testProductId,
        quantity: testQuantity,
      );

      // Act
      final result = await salesApi.createSale(request);

      // Assert: verifica que el SaleResponse tiene los campos correctos
      expect(result.id, 1);
      expect(result.totalAmount, 375.00);
      expect(result.createdAt, DateTime(2026, 5, 10, 10, 30, 0));
      expect(result.items, hasLength(1));
      expect(result.items[0].batchId, testBatchId);
      expect(result.items[0].productId, testProductId);
      expect(result.items[0].productName, 'Lavandina 3L');

      // Verifica que se llamó al endpoint correcto con el request serializado
      verify(
        () => mockDio.post(
          '/api/v1/sales',
          data: {'productId': testProductId, 'quantity': testQuantity},
        ),
      ).called(1);
    });

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en createSale con bad request (400)',
      () async {
        // Arrange: simula 400 Bad Request
        when(
          () => mockDio.post('/api/v1/sales', data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/sales'),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/sales'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act & Assert
        expect(
          () => salesApi.createSale(
            SaleRequest(productId: testProductId, quantity: testQuantity),
          ),
          throwsA(isA<ApiException>()),
        );
      },
    );

    // Error 403: debe lanzar AuthException
    test(
      'debe lanzar AuthException en createSale sin permisos (403)',
      () async {
        when(
          () => mockDio.post('/api/v1/sales', data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/sales'),
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/sales'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => salesApi.createSale(
            SaleRequest(productId: testProductId, quantity: testQuantity),
          ),
          throwsA(isA<AuthException>()),
        );
      },
    );

    // Error 500: debe lanzar ServerException
    test(
      'debe lanzar ServerException en createSale con error interno (500)',
      () async {
        when(
          () => mockDio.post('/api/v1/sales', data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/sales'),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/sales'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => salesApi.createSale(
            SaleRequest(productId: testProductId, quantity: testQuantity),
          ),
          throwsA(isA<ServerException>()),
        );
      },
    );

    // Error de red: debe lanzar NetworkException
    test('debe lanzar NetworkException en createSale sin conexión', () async {
      when(
        () => mockDio.post('/api/v1/sales', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/sales'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => salesApi.createSale(
          SaleRequest(productId: testProductId, quantity: testQuantity),
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getProducts', () {
    // Escenario feliz: GET /api/v1/products retorna 200 con lista de ProductResponse
    test(
      'debe GET /api/v1/products y retornar lista de ProductResponse',
      () async {
        // Arrange: respuesta simulada del backend
        final responseData = {
          'content': [
            {'id': 1, 'name': 'Producto A'},
            {'id': 2, 'name': 'Producto B'},
          ],
        };
        final response = Response(
          requestOptions: RequestOptions(path: '/api/v1/products'),
          data: responseData,
          statusCode: 200,
        );

        when(
          () => mockDio.get('/api/v1/products'),
        ).thenAnswer((_) async => response);

        // Act
        final result = await salesApi.getProducts();

        // Assert: verifica la lista de productos
        expect(result, hasLength(2));
        expect(result[0].id, 1);
        expect(result[0].name, 'Producto A');
        expect(result[1].id, 2);
        expect(result[1].name, 'Producto B');

        verify(() => mockDio.get('/api/v1/products')).called(1);
      },
    );

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en getProducts con bad request (400)',
      () async {
        when(() => mockDio.get('/api/v1/products')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products'),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/products'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(() => salesApi.getProducts(), throwsA(isA<ApiException>()));
      },
    );

    // Error 403: debe lanzar AuthException
    test(
      'debe lanzar AuthException en getProducts sin permisos (403)',
      () async {
        when(() => mockDio.get('/api/v1/products')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products'),
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/products'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(() => salesApi.getProducts(), throwsA(isA<AuthException>()));
      },
    );

    // Error 500: debe lanzar ServerException
    test(
      'debe lanzar ServerException en getProducts con error interno (500)',
      () async {
        when(() => mockDio.get('/api/v1/products')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/products'),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/products'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(() => salesApi.getProducts(), throwsA(isA<ServerException>()));
      },
    );

    // Error de red: debe lanzar NetworkException
    test('debe lanzar NetworkException en getProducts sin conexión', () async {
      when(() => mockDio.get('/api/v1/products')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/products'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(() => salesApi.getProducts(), throwsA(isA<NetworkException>()));
    });
  });

  group('getSales', () {
    // Escenario feliz: GET /api/v1/sales retorna 200 con lista de SaleResponse
    test('debe GET /api/v1/sales y retornar lista de SaleResponse', () async {
      // Arrange
      final responseData = {
        'content': [
          {
            'id': 1,
            'totalAmount': 15000.00,
            'createdAt': '2026-05-10T10:30:00.000',
            'items': [
              {
                'batchId': 42,
                'productId': 5,
                'productName': 'Lavandina 3L',
                'quantity': 2.5,
                'unitPrice': 150.00,
                'unitCost': 100.00,
              },
            ],
          },
          {
            'id': 2,
            'totalAmount': 20000.00,
            'createdAt': '2026-05-11T14:00:00.000',
            'items': [
              {
                'batchId': 43,
                'productId': 6,
                'productName': 'Jabón Líquido 1L',
                'quantity': 3.0,
                'unitPrice': 200.00,
                'unitCost': 120.00,
              },
            ],
          },
        ],
      };
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/sales'),
        data: responseData,
        statusCode: 200,
      );

      when(
        () => mockDio.get('/api/v1/sales'),
      ).thenAnswer((_) async => response);

      // Act
      final result = await salesApi.getSales();

      // Assert
      expect(result, hasLength(2));
      expect(result[0].id, 1);
      expect(result[0].totalAmount, 15000.00);
      expect(result[0].items, hasLength(1));
      expect(result[0].items[0].productId, 5);
      expect(result[0].items[0].productName, 'Lavandina 3L');
      expect(result[1].id, 2);
      expect(result[1].totalAmount, 20000.00);

      verify(() => mockDio.get('/api/v1/sales')).called(1);
    });

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en getSales con bad request (400)',
      () async {
        when(() => mockDio.get('/api/v1/sales')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/sales'),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/sales'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(() => salesApi.getSales(), throwsA(isA<ApiException>()));
      },
    );

    // Error 403: debe lanzar AuthException
    test('debe lanzar AuthException en getSales sin permisos (403)', () async {
      when(() => mockDio.get('/api/v1/sales')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/sales'),
          response: Response(
            statusCode: 403,
            requestOptions: RequestOptions(path: '/api/v1/sales'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(() => salesApi.getSales(), throwsA(isA<AuthException>()));
    });

    // Error 500: debe lanzar ServerException
    test(
      'debe lanzar ServerException en getSales con error interno (500)',
      () async {
        when(() => mockDio.get('/api/v1/sales')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/sales'),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/sales'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(() => salesApi.getSales(), throwsA(isA<ServerException>()));
      },
    );

    // Error de red: debe lanzar NetworkException
    test('debe lanzar NetworkException en getSales sin conexión', () async {
      when(() => mockDio.get('/api/v1/sales')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/sales'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(() => salesApi.getSales(), throwsA(isA<NetworkException>()));
    });
  });

  group('getSaleById', () {
    // Escenario feliz: GET /api/v1/sales/{id} retorna 200 con SaleResponse
    test('debe GET /api/v1/sales/{id} y retornar SaleResponse', () async {
      // Arrange
      const saleId = 1;
      final responseData = {
        'id': saleId,
        'totalAmount': 15000.00,
        'createdAt': '2026-05-10T10:30:00.000',
        'items': [
          {
            'batchId': 42,
            'productId': 5,
            'productName': 'Lavandina 3L',
            'quantity': 2.5,
            'unitPrice': 150.00,
            'unitCost': 100.00,
          },
        ],
      };
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/sales/$saleId'),
        data: responseData,
        statusCode: 200,
      );

      when(
        () => mockDio.get('/api/v1/sales/$saleId'),
      ).thenAnswer((_) async => response);

      // Act
      final result = await salesApi.getSaleById(saleId);

      // Assert
      expect(result.id, saleId);
      expect(result.totalAmount, 15000.00);
      expect(result.items, hasLength(1));
      expect(result.items[0].productId, 5);
      expect(result.items[0].productName, 'Lavandina 3L');

      verify(() => mockDio.get('/api/v1/sales/$saleId')).called(1);
    });

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en getSaleById con bad request (400)',
      () async {
        const saleId = 1;
        when(() => mockDio.get('/api/v1/sales/$saleId')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/sales/$saleId'),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/sales/$saleId'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => salesApi.getSaleById(saleId),
          throwsA(isA<ApiException>()),
        );
      },
    );

    // Error 403: debe lanzar AuthException
    test(
      'debe lanzar AuthException en getSaleById sin permisos (403)',
      () async {
        const saleId = 1;
        when(() => mockDio.get('/api/v1/sales/$saleId')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/sales/$saleId'),
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/sales/$saleId'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => salesApi.getSaleById(saleId),
          throwsA(isA<AuthException>()),
        );
      },
    );

    // Error 500: debe lanzar ServerException
    test(
      'debe lanzar ServerException en getSaleById con error interno (500)',
      () async {
        const saleId = 1;
        when(() => mockDio.get('/api/v1/sales/$saleId')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/sales/$saleId'),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/sales/$saleId'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => salesApi.getSaleById(saleId),
          throwsA(isA<ServerException>()),
        );
      },
    );

    // Error de red: debe lanzar NetworkException
    test('debe lanzar NetworkException en getSaleById sin conexión', () async {
      const saleId = 1;
      when(() => mockDio.get('/api/v1/sales/$saleId')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/sales/$saleId'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => salesApi.getSaleById(saleId),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getBatchesByProduct', () {
    // Escenario feliz: GET /api/v1/production-batches/product/{id} retorna 200
    test(
      'debe GET /api/v1/production-batches/product/{id} y retornar lista',
      () async {
        // Arrange
        final responseData = {
          'content': [
            {'id': 1, 'productId': testProductId, 'currentStock': 100.0},
            {'id': 2, 'productId': testProductId, 'currentStock': 50.0},
          ],
        };
        final response = Response(
          requestOptions: RequestOptions(
            path: '/api/v1/production-batches/product/$testProductId',
          ),
          data: responseData,
          statusCode: 200,
        );

        when(
          () =>
              mockDio.get('/api/v1/production-batches/product/$testProductId'),
        ).thenAnswer((_) async => response);

        // Act
        final result = await salesApi.getBatchesByProduct(testProductId);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, 1);
        expect(result[0].productId, testProductId);
        expect(result[0].currentStock, 100.0);
        expect(result[1].id, 2);
        expect(result[1].currentStock, 50.0);

        verify(
          () =>
              mockDio.get('/api/v1/production-batches/product/$testProductId'),
        ).called(1);
      },
    );

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en getBatchesByProduct con bad request (400)',
      () async {
        when(
          () =>
              mockDio.get('/api/v1/production-batches/product/$testProductId'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/production-batches/product/$testProductId',
            ),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(
                path: '/api/v1/production-batches/product/$testProductId',
              ),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => salesApi.getBatchesByProduct(testProductId),
          throwsA(isA<ApiException>()),
        );
      },
    );

    // Error 403: debe lanzar AuthException
    test(
      'debe lanzar AuthException en getBatchesByProduct sin permisos (403)',
      () async {
        when(
          () =>
              mockDio.get('/api/v1/production-batches/product/$testProductId'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/production-batches/product/$testProductId',
            ),
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(
                path: '/api/v1/production-batches/product/$testProductId',
              ),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => salesApi.getBatchesByProduct(testProductId),
          throwsA(isA<AuthException>()),
        );
      },
    );

    // Error 500: debe lanzar ServerException
    test(
      'debe lanzar ServerException en getBatchesByProduct con error interno (500)',
      () async {
        when(
          () =>
              mockDio.get('/api/v1/production-batches/product/$testProductId'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/production-batches/product/$testProductId',
            ),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(
                path: '/api/v1/production-batches/product/$testProductId',
              ),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => salesApi.getBatchesByProduct(testProductId),
          throwsA(isA<ServerException>()),
        );
      },
    );

    // Error de red: debe lanzar NetworkException
    test(
      'debe lanzar NetworkException en getBatchesByProduct sin conexión',
      () async {
        when(
          () =>
              mockDio.get('/api/v1/production-batches/product/$testProductId'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/production-batches/product/$testProductId',
            ),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => salesApi.getBatchesByProduct(testProductId),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });
}
