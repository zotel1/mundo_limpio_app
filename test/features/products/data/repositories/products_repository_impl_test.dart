// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/products/data/api/products_api.dart';
import 'package:mundo_limpio_app/features/products/data/models/product_model.dart';
import 'package:mundo_limpio_app/features/products/data/repositories/products_repository_impl.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';

class MockProductsApi extends Mock implements ProductsApi {}

void main() {
  late MockProductsApi mockApi;
  late ProductsRepositoryImpl repository;

  setUp(() {
    mockApi = MockProductsApi();
    repository = ProductsRepositoryImpl(api: mockApi);
  });

  group('ProductsRepositoryImpl', () {
    group('getAll', () {
      test('debe retornar lista de Product activos desde la API', () async {
        // Arrange
        final models = [
          ProductModel(
            id: 1,
            sku: 'PROD-001',
            name: 'Jabón',
            minPrice: 150.0,
            active: true,
          ),
          ProductModel(
            id: 2,
            sku: 'PROD-002',
            name: 'Detergente',
            minPrice: 200.0,
            active: true,
          ),
        ];
        when(() => mockApi.getProducts()).thenAnswer((_) async => models);

        // Act
        final result = await repository.getAll();

        // Assert
        expect(result, isA<List<Product>>());
        expect(result, hasLength(2));
        expect(result[0].name, 'Jabón');
        expect(result[1].name, 'Detergente');
        verify(() => mockApi.getProducts()).called(1);
      });

      test('debe lanzar ApiException cuando la API falla', () async {
        // Arrange
        when(
          () => mockApi.getProducts(),
        ).thenThrow(const ApiException('Error', 500));

        // Act & Assert
        expect(
          () async => await repository.getAll(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getAllProducts', () {
      test('debe retornar lista de todos los Product desde la API', () async {
        // Arrange
        final models = [
          ProductModel(
            id: 1,
            sku: 'PROD-001',
            name: 'Jabón',
            minPrice: 150.0,
            active: true,
          ),
          ProductModel(
            id: 2,
            sku: 'PROD-002',
            name: 'Detergente',
            minPrice: 200.0,
            active: false,
          ),
        ];
        when(() => mockApi.getAllProducts()).thenAnswer((_) async => models);

        // Act
        final result = await repository.getAllProducts();

        // Assert
        expect(result, hasLength(2));
        expect(result[1].active, false);
        verify(() => mockApi.getAllProducts()).called(1);
      });
    });

    group('getById', () {
      test('debe retornar Product por ID', () async {
        // Arrange
        final model = ProductModel(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón',
          minPrice: 150.0,
          active: true,
        );
        when(() => mockApi.getProductById(1)).thenAnswer((_) async => model);

        // Act
        final result = await repository.getById(1);

        // Assert
        expect(result, isA<Product>());
        expect(result.id, 1);
        expect(result.name, 'Jabón');
        verify(() => mockApi.getProductById(1)).called(1);
      });

      test('debe lanzar ApiException cuando la API falla', () async {
        when(
          () => mockApi.getProductById(999),
        ).thenThrow(const ApiException('Not found', 404));

        expect(
          () async => await repository.getById(999),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getBySku', () {
      test('debe retornar Product por SKU', () async {
        // Arrange
        final model = ProductModel(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón',
          minPrice: 150.0,
          active: true,
        );
        when(
          () => mockApi.getProductBySku('PROD-001'),
        ).thenAnswer((_) async => model);

        // Act
        final result = await repository.getBySku('PROD-001');

        // Assert
        expect(result, isA<Product>());
        expect(result.sku, 'PROD-001');
        verify(() => mockApi.getProductBySku('PROD-001')).called(1);
      });
    });

    group('create', () {
      test('debe retornar el Product creado', () async {
        // Arrange
        const product = Product(
          id: 0,
          sku: 'PROD-NEW',
          name: 'Nuevo',
          minPrice: 100.0,
          active: true,
        );
        final createdModel = ProductModel(
          id: 1,
          sku: 'PROD-NEW',
          name: 'Nuevo',
          minPrice: 100.0,
          active: true,
        );
        when(
          () => mockApi.createProduct(any()),
        ).thenAnswer((_) async => createdModel);

        // Act
        final result = await repository.create(product);

        // Assert
        expect(result, isA<Product>());
        expect(result.id, 1);
        verify(() => mockApi.createProduct(any())).called(1);
      });
    });

    group('update', () {
      test('debe retornar el Product actualizado', () async {
        // Arrange
        const product = Product(
          id: 1,
          sku: 'PROD-001',
          name: 'Modificado',
          minPrice: 200.0,
          active: true,
        );
        final updatedModel = ProductModel(
          id: 1,
          sku: 'PROD-001',
          name: 'Modificado',
          minPrice: 200.0,
          active: true,
        );
        when(
          () => mockApi.updateProduct(any(), any()),
        ).thenAnswer((_) async => updatedModel);

        // Act
        final result = await repository.update(product);

        // Assert
        expect(result, isA<Product>());
        expect(result.name, 'Modificado');
      });
    });

    group('delete', () {
      test('debe llamar a deleteProduct de la API', () async {
        // Arrange
        when(() => mockApi.deleteProduct(1)).thenAnswer((_) async {});

        // Act
        await repository.delete(1);

        // Assert
        verify(() => mockApi.deleteProduct(1)).called(1);
      });

      test('debe lanzar ApiException cuando la API falla', () async {
        when(
          () => mockApi.deleteProduct(1),
        ).thenThrow(const ApiException('Forbidden', 403));

        expect(
          () async => await repository.delete(1),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('reactivate', () {
      test('debe retornar el Product reactivado', () async {
        // Arrange
        final reactivatedModel = ProductModel(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón',
          minPrice: 150.0,
          active: true,
        );
        when(
          () => mockApi.reactivateProduct(1),
        ).thenAnswer((_) async => reactivatedModel);

        // Act
        final result = await repository.reactivate(1);

        // Assert
        expect(result, isA<Product>());
        expect(result.active, true);
        verify(() => mockApi.reactivateProduct(1)).called(1);
      });
    });
  });
}
