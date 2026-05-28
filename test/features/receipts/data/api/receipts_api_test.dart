// Pruebas unitarias para ReceiptsApi.
// Verifica que las llamadas HTTP a los endpoints de recibos
// se hacen correctamente con FormData (multipart) y JSON, y que
// los errores HTTP se convierten a ApiException con el subtipo correcto.
//
// TDD: RED — test escrito antes que la implementación

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/receipts/data/api/receipts_api.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/product_line_confirm_dto.dart';

// Mock de Dio para aislar las pruebas HTTP de la red real
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ReceiptsApi receiptsApi;
  late File testImageFile;

  setUp(() {
    mockDio = MockDio();
    receiptsApi = ReceiptsApi(dio: mockDio);

    // Crea un archivo temporal real para que MultipartFile.fromFile
    // pueda leerlo (necesita acceder a File.length en disco).
    testImageFile = File('${Directory.systemTemp.path}/receipt_test_ocr.jpg');
    testImageFile.writeAsStringSync('fake-image-bytes');
  });

  tearDown(() {
    if (testImageFile.existsSync()) {
      testImageFile.deleteSync();
    }
  });

  group('processReceipt', () {
    // Escenario feliz: POST /api/v1/receipts/process con FormData retorna 200
    test('debe POST multipart /api/v1/receipts/process y retornar '
        'ReceiptProcessResponse en 200', () async {
      // Arrange: respuesta simulada del backend OCR
      final responseData = {
        'detectedSupplier': 'Proveedor X',
        'detectedDate': '2026-05-15',
        'lines': [
          {
            'name': 'Leche',
            'quantity': 2,
            'unitPrice': 150.0,
            'confidence': 0.95,
            'bulkProductId': 1,
          },
        ],
        'imageUrl': 'https://storage.example.com/receipts/img123.jpg',
      };
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
        data: responseData,
        statusCode: 200,
      );

      when(
        () =>
            mockDio.post('/api/v1/receipts/process', data: any(named: 'data')),
      ).thenAnswer((_) async => response);

      // Act
      final result = await receiptsApi.processReceipt(testImageFile.path);

      // Assert: verifica que el ReceiptProcessResponse tiene los campos correctos
      expect(result.detectedSupplier, 'Proveedor X');
      expect(result.detectedDate, '2026-05-15');
      expect(
        result.imageUrl,
        'https://storage.example.com/receipts/img123.jpg',
      );
      expect(result.lines, hasLength(1));
      expect(result.lines[0].name, 'Leche');
      expect(result.lines[0].quantity, 2);
      expect(result.lines[0].unitPrice, 150.0);
      expect(result.lines[0].confidence, 0.95);
      expect(result.lines[0].bulkProductId, 1);

      // Verifica que se llamó al endpoint correcto
      verify(
        () =>
            mockDio.post('/api/v1/receipts/process', data: any(named: 'data')),
      ).called(1);
    });

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en processReceipt con bad request (400)',
      () async {
        when(
          () => mockDio.post(
            '/api/v1/receipts/process',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => receiptsApi.processReceipt(testImageFile.path),
          throwsA(isA<ApiException>()),
        );
      },
    );

    // Error 403: debe lanzar AuthException
    test(
      'debe lanzar AuthException en processReceipt sin permisos (403)',
      () async {
        when(
          () => mockDio.post(
            '/api/v1/receipts/process',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => receiptsApi.processReceipt(testImageFile.path),
          throwsA(isA<AuthException>()),
        );
      },
    );

    // Error 422: debe lanzar ApiException (genérico, no auth ni server)
    test('debe lanzar ApiException en processReceipt con '
        'entidad no procesable (422)', () async {
      when(
        () =>
            mockDio.post('/api/v1/receipts/process', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
          response: Response(
            statusCode: 422,
            requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => receiptsApi.processReceipt(testImageFile.path),
        throwsA(isA<ApiException>()),
      );
    });

    // Error 500: debe lanzar ServerException
    test('debe lanzar ServerException en processReceipt con '
        'error interno (500)', () async {
      when(
        () =>
            mockDio.post('/api/v1/receipts/process', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => receiptsApi.processReceipt(testImageFile.path),
        throwsA(isA<ServerException>()),
      );
    });

    // Error de red: debe lanzar NetworkException
    test(
      'debe lanzar NetworkException en processReceipt sin conexión',
      () async {
        when(
          () => mockDio.post(
            '/api/v1/receipts/process',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts/process'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => receiptsApi.processReceipt(testImageFile.path),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });

  group('confirmReceipt', () {
    // Datos comunes para los tests de confirmReceipt
    final testRequest = ReceiptConfirmRequest(
      imageUrl: 'https://storage.example.com/receipts/img123.jpg',
      supplierName: 'Proveedor X',
      purchaseDate: '2026-05-15',
      lines: [
        ProductLineConfirmDto(
          description: 'Leche',
          quantity: 2,
          unitPrice: 150.0,
          bulkProductId: 1,
        ),
      ],
    );

    // Escenario feliz: POST /api/v1/receipts/confirm con JSON retorna 201
    test('debe POST JSON /api/v1/receipts/confirm y retornar '
        'PurchaseResponse en 201', () async {
      // Arrange: respuesta simulada del backend
      final responseData = {
        'id': 1,
        'imageUrl': 'https://storage.example.com/receipts/img123.jpg',
        'supplierName': 'Proveedor X',
        'purchaseDate': '2026-05-15',
        'total': 300.0,
        'items': [
          {
            'id': 1,
            'description': 'Leche',
            'quantity': 2,
            'unitPrice': 150.0,
            'totalPrice': 300.0,
            'bulkProductId': 1,
          },
        ],
      };
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
        data: responseData,
        statusCode: 201,
      );

      when(
        () =>
            mockDio.post('/api/v1/receipts/confirm', data: any(named: 'data')),
      ).thenAnswer((_) async => response);

      // Act
      final result = await receiptsApi.confirmReceipt(testRequest);

      // Assert: verifica que el PurchaseResponse tiene los campos correctos
      expect(result.id, 1);
      expect(
        result.imageUrl,
        'https://storage.example.com/receipts/img123.jpg',
      );
      expect(result.supplierName, 'Proveedor X');
      expect(result.purchaseDate, DateTime(2026, 5, 15));
      expect(result.total, 300.0);
      expect(result.items, hasLength(1));
      expect(result.items[0].id, 1);
      expect(result.items[0].description, 'Leche');
      expect(result.items[0].quantity, 2);
      expect(result.items[0].unitPrice, 150.0);
      expect(result.items[0].totalPrice, 300.0);
      expect(result.items[0].bulkProductId, 1);

      // Verifica que se llamó al endpoint correcto con el JSON esperado
      verify(
        () => mockDio.post(
          '/api/v1/receipts/confirm',
          data: {
            'imageUrl': 'https://storage.example.com/receipts/img123.jpg',
            'supplierName': 'Proveedor X',
            'purchaseDate': '2026-05-15',
            'lines': [
              {
                'description': 'Leche',
                'quantity': 2,
                'unitPrice': 150.0,
                'bulkProductId': 1,
              },
            ],
          },
        ),
      ).called(1);
    });

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en confirmReceipt con bad request (400)',
      () async {
        when(
          () => mockDio.post(
            '/api/v1/receipts/confirm',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => receiptsApi.confirmReceipt(testRequest),
          throwsA(isA<ApiException>()),
        );
      },
    );

    // Error 403: debe lanzar AuthException
    test(
      'debe lanzar AuthException en confirmReceipt sin permisos (403)',
      () async {
        when(
          () => mockDio.post(
            '/api/v1/receipts/confirm',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => receiptsApi.confirmReceipt(testRequest),
          throwsA(isA<AuthException>()),
        );
      },
    );

    // Error 422: debe lanzar ApiException (genérico, no auth ni server)
    test('debe lanzar ApiException en confirmReceipt con '
        'entidad no procesable (422)', () async {
      when(
        () =>
            mockDio.post('/api/v1/receipts/confirm', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
          response: Response(
            statusCode: 422,
            requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => receiptsApi.confirmReceipt(testRequest),
        throwsA(isA<ApiException>()),
      );
    });

    // Error 500: debe lanzar ServerException
    test('debe lanzar ServerException en confirmReceipt con '
        'error interno (500)', () async {
      when(
        () =>
            mockDio.post('/api/v1/receipts/confirm', data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => receiptsApi.confirmReceipt(testRequest),
        throwsA(isA<ServerException>()),
      );
    });

    // Error de red: debe lanzar NetworkException
    test(
      'debe lanzar NetworkException en confirmReceipt sin conexión',
      () async {
        when(
          () => mockDio.post(
            '/api/v1/receipts/confirm',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts/confirm'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => receiptsApi.confirmReceipt(testRequest),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });

  group('getPurchases', () {
    // Escenario feliz: GET /api/v1/receipts retorna 200 con lista
    test(
      'debe GET /api/v1/receipts y retornar lista de PurchaseResponse',
      () async {
        // Arrange
        final responseData = [
          {
            'id': 1,
            'imageUrl': 'https://storage.example.com/receipts/img1.jpg',
            'supplierName': 'Proveedor X',
            'purchaseDate': '2026-05-15',
            'total': 300.0,
            'items': [
              {
                'id': 1,
                'description': 'Leche',
                'quantity': 2,
                'unitPrice': 150.0,
                'totalPrice': 300.0,
                'bulkProductId': 1,
              },
            ],
          },
          {
            'id': 2,
            'imageUrl': 'https://storage.example.com/receipts/img2.jpg',
            'supplierName': 'Proveedor Y',
            'purchaseDate': '2026-05-16',
            'total': 500.0,
            'items': [
              {
                'id': 2,
                'description': 'Harina',
                'quantity': 5,
                'unitPrice': 100.0,
                'totalPrice': 500.0,
                'bulkProductId': 2,
              },
            ],
          },
        ];
        final response = Response(
          requestOptions: RequestOptions(path: '/api/v1/receipts'),
          data: responseData,
          statusCode: 200,
        );

        when(
          () => mockDio.get('/api/v1/receipts'),
        ).thenAnswer((_) async => response);

        // Act
        final result = await receiptsApi.getPurchases();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, 1);
        expect(result[0].supplierName, 'Proveedor X');
        expect(result[0].total, 300.0);
        expect(result[1].id, 2);
        expect(result[1].supplierName, 'Proveedor Y');
        expect(result[1].total, 500.0);

        verify(() => mockDio.get('/api/v1/receipts')).called(1);
      },
    );

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en getPurchases con bad request (400)',
      () async {
        when(() => mockDio.get('/api/v1/receipts')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts'),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/receipts'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(() => receiptsApi.getPurchases(), throwsA(isA<ApiException>()));
      },
    );

    // Error 403: debe lanzar AuthException
    test(
      'debe lanzar AuthException en getPurchases sin permisos (403)',
      () async {
        when(() => mockDio.get('/api/v1/receipts')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts'),
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/receipts'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(() => receiptsApi.getPurchases(), throwsA(isA<AuthException>()));
      },
    );

    // Error 500: debe lanzar ServerException
    test(
      'debe lanzar ServerException en getPurchases con error interno (500)',
      () async {
        when(() => mockDio.get('/api/v1/receipts')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/receipts'),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/receipts'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => receiptsApi.getPurchases(),
          throwsA(isA<ServerException>()),
        );
      },
    );

    // Error de red: debe lanzar NetworkException
    test('debe lanzar NetworkException en getPurchases sin conexión', () async {
      when(() => mockDio.get('/api/v1/receipts')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/receipts'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => receiptsApi.getPurchases(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getPurchaseById', () {
    // Escenario feliz: GET /api/v1/receipts/{id} retorna 200
    test(
      'debe GET /api/v1/receipts/{id} y retornar PurchaseResponse',
      () async {
        // Arrange
        const purchaseId = 1;
        final responseData = {
          'id': purchaseId,
          'imageUrl': 'https://storage.example.com/receipts/img1.jpg',
          'supplierName': 'Proveedor X',
          'purchaseDate': '2026-05-15',
          'total': 300.0,
          'items': [
            {
              'id': 1,
              'description': 'Leche',
              'quantity': 2,
              'unitPrice': 150.0,
              'totalPrice': 300.0,
              'bulkProductId': 1,
            },
          ],
        };
        final response = Response(
          requestOptions: RequestOptions(path: '/api/v1/receipts/$purchaseId'),
          data: responseData,
          statusCode: 200,
        );

        when(
          () => mockDio.get('/api/v1/receipts/$purchaseId'),
        ).thenAnswer((_) async => response);

        // Act
        final result = await receiptsApi.getPurchaseById(purchaseId);

        // Assert
        expect(result.id, purchaseId);
        expect(result.supplierName, 'Proveedor X');
        expect(result.total, 300.0);
        expect(result.items, hasLength(1));
        expect(result.items[0].description, 'Leche');
        expect(result.items[0].quantity, 2);

        verify(() => mockDio.get('/api/v1/receipts/$purchaseId')).called(1);
      },
    );

    // Error 400: debe lanzar ApiException
    test(
      'debe lanzar ApiException en getPurchaseById con bad request (400)',
      () async {
        const purchaseId = 1;
        when(() => mockDio.get('/api/v1/receipts/$purchaseId')).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/receipts/$purchaseId',
            ),
            response: Response(
              statusCode: 400,
              requestOptions: RequestOptions(
                path: '/api/v1/receipts/$purchaseId',
              ),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => receiptsApi.getPurchaseById(purchaseId),
          throwsA(isA<ApiException>()),
        );
      },
    );

    // Error 403: debe lanzar AuthException
    test(
      'debe lanzar AuthException en getPurchaseById sin permisos (403)',
      () async {
        const purchaseId = 1;
        when(() => mockDio.get('/api/v1/receipts/$purchaseId')).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/receipts/$purchaseId',
            ),
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(
                path: '/api/v1/receipts/$purchaseId',
              ),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => receiptsApi.getPurchaseById(purchaseId),
          throwsA(isA<AuthException>()),
        );
      },
    );

    // Error 500: debe lanzar ServerException
    test(
      'debe lanzar ServerException en getPurchaseById con error interno (500)',
      () async {
        const purchaseId = 1;
        when(() => mockDio.get('/api/v1/receipts/$purchaseId')).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/receipts/$purchaseId',
            ),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(
                path: '/api/v1/receipts/$purchaseId',
              ),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => receiptsApi.getPurchaseById(purchaseId),
          throwsA(isA<ServerException>()),
        );
      },
    );

    // Error de red: debe lanzar NetworkException
    test(
      'debe lanzar NetworkException en getPurchaseById sin conexión',
      () async {
        const purchaseId = 1;
        when(() => mockDio.get('/api/v1/receipts/$purchaseId')).thenThrow(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/receipts/$purchaseId',
            ),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => receiptsApi.getPurchaseById(purchaseId),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });
}
