// TDD: GREEN — test que validan el read-through cache offline/online
// del ProductsRepositoryImpl.
//
// Cobertura:
// - GET online → API + cache-prime → entidades
// - GET offline → caché → entidades
// - GET offline + empty cache → ApiException
// - getById online → API + cache-prime
// - getById offline → caché getById → entidad
// - getById offline + cache miss → ApiException
// - create → API + cache upsert
// - update → API + cache upsert
// - delete → API + cache upsert (inactive)
// - reactivate → API + cache upsert
// - API failure → ApiException rethrown, cache no tocado

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';
import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/product_cache_dao.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/products/data/api/products_api.dart';
import 'package:mundo_limpio_app/features/products/data/models/product_model.dart';
import 'package:mundo_limpio_app/features/products/data/repositories/products_repository_impl.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';

class MockProductsApi extends Mock implements ProductsApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockProductCacheDao extends Mock implements ProductCacheDao {}

void main() {
  late MockProductsApi mockApi;
  late MockConnectivityService mockConnectivity;
  late MockProductCacheDao mockCacheDao;
  late ProductsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      ProductCacheData(
        id: 0,
        name: '',
        updatedAt: DateTime.now(),
        active: true,
      ),
    );
    registerFallbackValue(<ProductCacheData>[]);
  });

  setUp(() {
    mockApi = MockProductsApi();
    mockConnectivity = MockConnectivityService();
    mockCacheDao = MockProductCacheDao();
    repository = ProductsRepositoryImpl(
      api: mockApi,
      connectivityService: mockConnectivity,
      productCacheDao: mockCacheDao,
    );
  });

  group('ProductsRepositoryImpl', () {
    group('getAll — online path', () {
      setUp(() {
        when(() => mockConnectivity.isOnline).thenReturn(true);
      });

      test('debe llamar API, cachear y retornar entidades', () async {
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
        when(() => mockCacheDao.upsertAll(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.getAll();

        // Assert
        expect(result, isA<List<Product>>());
        expect(result, hasLength(2));
        expect(result[0].name, 'Jabón');
        expect(result[1].name, 'Detergente');
        verify(() => mockApi.getProducts()).called(1);
        verify(() => mockCacheDao.upsertAll(any())).called(1);
      });

      test(
        'debe lanzar ApiException cuando la API falla sin tocar caché',
        () async {
          // Arrange
          when(
            () => mockApi.getProducts(),
          ).thenThrow(const UnknownApiException('Error', 500));

          // Act & Assert
          expect(
            () async => await repository.getAll(),
            throwsA(isA<ApiException>()),
          );
          verifyNever(() => mockCacheDao.upsertAll(any()));
        },
      );
    });

    group('getAll — offline path', () {
      setUp(() {
        when(() => mockConnectivity.isOnline).thenReturn(false);
      });

      test('debe leer de caché cuando hay datos', () async {
        // Arrange
        final cached = [
          ProductCacheData(
            id: 1,
            name: 'Jabón',
            sku: 'PROD-001',
            minPrice: 150.0,
            active: true,
            updatedAt: DateTime.now(),
          ),
        ];
        when(() => mockCacheDao.getAll()).thenAnswer((_) async => cached);

        // Act
        final result = await repository.getAll();

        // Assert
        expect(result, hasLength(1));
        expect(result[0].name, 'Jabón');
        verify(() => mockCacheDao.getAll()).called(1);
        verifyNever(() => mockApi.getProducts());
      });

      test('debe lanzar ApiException cuando el caché está vacío', () async {
        // Arrange
        when(() => mockCacheDao.getAll()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () async => await repository.getAll(),
          throwsA(isA<ApiException>()),
        );
        verify(() => mockCacheDao.getAll()).called(1);
        verifyNever(() => mockApi.getProducts());
      });
    });

    group('getAllProducts — online path', () {
      setUp(() {
        when(() => mockConnectivity.isOnline).thenReturn(true);
      });

      test('debe llamar API, cachear y retornar entidades', () async {
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
        when(() => mockCacheDao.upsertAll(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.getAllProducts();

        // Assert
        expect(result, hasLength(2));
        expect(result[1].active, false);
        verify(() => mockApi.getAllProducts()).called(1);
        verify(() => mockCacheDao.upsertAll(any())).called(1);
      });
    });

    group('getAllProducts — offline path', () {
      setUp(() {
        when(() => mockConnectivity.isOnline).thenReturn(false);
      });

      test('debe leer de caché cuando hay datos', () async {
        // Arrange
        final cached = [
          ProductCacheData(
            id: 1,
            name: 'Jabón',
            sku: 'PROD-001',
            minPrice: 150.0,
            active: true,
            updatedAt: DateTime.now(),
          ),
        ];
        when(() => mockCacheDao.getAll()).thenAnswer((_) async => cached);

        // Act
        final result = await repository.getAllProducts();

        // Assert
        expect(result, hasLength(1));
        verify(() => mockCacheDao.getAll()).called(1);
        verifyNever(() => mockApi.getAllProducts());
      });
    });

    group('getById — online path', () {
      setUp(() {
        when(() => mockConnectivity.isOnline).thenReturn(true);
      });

      test('debe llamar API, cachear y retornar entidad', () async {
        // Arrange
        final model = ProductModel(
          id: 1,
          sku: 'PROD-001',
          name: 'Jabón',
          minPrice: 150.0,
          active: true,
        );
        when(() => mockApi.getProductById(1)).thenAnswer((_) async => model);
        when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.getById(1);

        // Assert
        expect(result, isA<Product>());
        expect(result.id, 1);
        expect(result.name, 'Jabón');
        verify(() => mockApi.getProductById(1)).called(1);
        verify(() => mockCacheDao.upsert(any())).called(1);
      });
    });

    group('getById — offline path', () {
      setUp(() {
        when(() => mockConnectivity.isOnline).thenReturn(false);
      });

      test('debe leer de caché cuando existe el producto', () async {
        // Arrange
        final cached = ProductCacheData(
          id: 1,
          name: 'Jabón',
          sku: 'PROD-001',
          minPrice: 150.0,
          active: true,
          updatedAt: DateTime.now(),
        );
        when(() => mockCacheDao.getById(1)).thenAnswer((_) async => cached);

        // Act
        final result = await repository.getById(1);

        // Assert
        expect(result.id, 1);
        expect(result.name, 'Jabón');
        verify(() => mockCacheDao.getById(1)).called(1);
        verifyNever(() => mockApi.getProductById(any()));
      });

      test(
        'debe lanzar ApiException cuando el producto no está en caché',
        () async {
          // Arrange
          when(() => mockCacheDao.getById(999)).thenAnswer((_) async => null);

          // Act & Assert
          expect(
            () async => await repository.getById(999),
            throwsA(isA<ApiException>()),
          );
          verify(() => mockCacheDao.getById(999)).called(1);
          verifyNever(() => mockApi.getProductById(any()));
        },
      );
    });

    group('getBySku', () {
      test('debe retornar Product por SKU (siempre online)', () async {
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
      test('debe llamar API y cachear el resultado', () async {
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
        when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.create(product);

        // Assert
        expect(result, isA<Product>());
        expect(result.id, 1);
        verify(() => mockApi.createProduct(any())).called(1);
        verify(() => mockCacheDao.upsert(any())).called(1);
      });
    });

    group('update', () {
      test('debe llamar API y cachear el resultado', () async {
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
        when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.update(product);

        // Assert
        expect(result, isA<Product>());
        expect(result.name, 'Modificado');
        verify(() => mockApi.updateProduct(any(), any())).called(1);
        verify(() => mockCacheDao.upsert(any())).called(1);
      });
    });

    group('delete', () {
      test('debe llamar API y marcar como inactivo en caché', () async {
        // Arrange
        final cached = ProductCacheData(
          id: 1,
          name: 'Jabón',
          sku: 'PROD-001',
          minPrice: 150.0,
          active: true,
          updatedAt: DateTime.now(),
        );
        when(() => mockApi.deleteProduct(1)).thenAnswer((_) async {});
        when(() => mockCacheDao.getById(1)).thenAnswer((_) async => cached);
        when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

        // Act
        await repository.delete(1);

        // Assert
        verify(() => mockApi.deleteProduct(1)).called(1);
        verify(() => mockCacheDao.getById(1)).called(1);
        verify(() => mockCacheDao.upsert(any())).called(1);
      });

      test(
        'debe lanzar ApiException cuando la API falla sin tocar caché',
        () async {
          // Arrange
          when(
            () => mockApi.deleteProduct(1),
          ).thenThrow(const UnknownApiException('Forbidden', 403));

          // Act & Assert
          expect(
            () async => await repository.delete(1),
            throwsA(isA<ApiException>()),
          );
          verifyNever(() => mockCacheDao.getById(any()));
          verifyNever(() => mockCacheDao.upsert(any()));
        },
      );
    });

    group('reactivate', () {
      test('debe llamar API y cachear el resultado', () async {
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
        when(() => mockCacheDao.upsert(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.reactivate(1);

        // Assert
        expect(result, isA<Product>());
        expect(result.active, true);
        verify(() => mockApi.reactivateProduct(1)).called(1);
        verify(() => mockCacheDao.upsert(any())).called(1);
      });
    });
  });
}
