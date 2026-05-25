// TDD: RED — test escrito antes que la implementación
//
// Pruebas unitarias para ProductsProvider.
//
// Verifica:
// - Estado inicial correcto
// - loadProducts, loadAllProducts, loadProduct cargan datos
// - createProduct, updateProduct, deleteProduct, reactivateProduct exitosos
// - ChangeNotifier notifica listeners
// - ApiException y error genérico manejados correctamente

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/domain/repositories/i_products_repository.dart';
import 'package:mundo_limpio_app/features/products/presentation/providers/products_provider.dart';

class MockProductsRepository extends Mock implements IProductsRepository {}

void main() {
  late MockProductsRepository mockRepo;
  late ProductsProvider provider;

  setUpAll(() {
    registerFallbackValue(const Product(id: 0, name: ''));
  });

  setUp(() {
    mockRepo = MockProductsRepository();
    provider = ProductsProvider(mockRepo);

    // Stubs por defecto
    when(() => mockRepo.getAll()).thenAnswer((_) async => []);
    when(() => mockRepo.getAllProducts()).thenAnswer((_) async => []);
    when(
      () => mockRepo.getById(any()),
    ).thenAnswer((_) async => const Product(id: 1, name: 'Test'));
    when(() => mockRepo.getBySku(any())).thenAnswer(
      (_) async => const Product(id: 1, sku: 'SKU001', name: 'Test'),
    );
    when(
      () => mockRepo.create(any()),
    ).thenAnswer((_) async => const Product(id: 1, name: 'Test Product'));
    when(
      () => mockRepo.update(any()),
    ).thenAnswer((_) async => const Product(id: 1, name: 'Updated Product'));
    when(() => mockRepo.delete(any())).thenAnswer((_) async {});
    when(() => mockRepo.reactivate(any())).thenAnswer(
      (_) async => const Product(id: 1, name: 'Reactivated', active: true),
    );
  });

  group('estado inicial', () {
    test('debe iniciar con status initial', () {
      expect(provider.status, ProductStatus.initial);
    });

    test('debe iniciar sin error', () {
      expect(provider.error, isNull);
    });

    test('isLoading debe ser false al iniciar', () {
      expect(provider.isLoading, isFalse);
    });

    test('debe iniciar con lista vacía', () {
      expect(provider.products, isEmpty);
    });

    test('currentProduct debe ser null al iniciar', () {
      expect(provider.currentProduct, isNull);
    });
  });

  group('loadProducts', () {
    test('debe cargar productos activos y setear status loaded', () async {
      final products = [
        const Product(id: 1, sku: 'SKU001', name: 'Alcohol'),
        const Product(id: 2, sku: 'SKU002', name: 'Detergente'),
      ];
      when(() => mockRepo.getAll()).thenAnswer((_) async => products);

      await provider.loadProducts();

      expect(provider.status, ProductStatus.loaded);
      expect(provider.products, products);
      expect(provider.isLoading, isFalse);
    });

    test('debe cargar lista vacía y setear status loaded', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);

      await provider.loadProducts();

      expect(provider.status, ProductStatus.loaded);
      expect(provider.products, isEmpty);
    });

    test('debe setear error cuando falla con ApiException', () async {
      when(
        () => mockRepo.getAll(),
      ).thenThrow(const ApiException('Error de red', 500));

      await provider.loadProducts();

      expect(provider.status, ProductStatus.error);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('debe setear error genérico con excepción desconocida', () async {
      when(() => mockRepo.getAll()).thenThrow(Exception('Algo salió mal'));

      await provider.loadProducts();

      expect(provider.status, ProductStatus.error);
      expect(provider.error, 'Error inesperado. Intentalo de nuevo.');
    });
  });

  group('loadAllProducts', () {
    test('debe cargar todos los productos y setear status loaded', () async {
      final allProducts = [
        const Product(id: 1, sku: 'SKU001', name: 'Activo', active: true),
        const Product(id: 2, sku: 'SKU002', name: 'Inactivo', active: false),
      ];
      when(
        () => mockRepo.getAllProducts(),
      ).thenAnswer((_) async => allProducts);

      await provider.loadAllProducts();

      expect(provider.status, ProductStatus.loaded);
      expect(provider.products, allProducts);
    });
  });

  group('loadProduct', () {
    test(
      'debe cargar un producto individual y setear currentProduct',
      () async {
        const product = Product(id: 5, sku: 'SKU005', name: 'Detalle');
        when(() => mockRepo.getById(5)).thenAnswer((_) async => product);

        await provider.loadProduct(5);

        expect(provider.status, ProductStatus.loaded);
        expect(provider.currentProduct, product);
      },
    );
  });

  group('createProduct', () {
    test('debe crear producto exitosamente', () async {
      const newProduct = Product(id: 0, sku: 'SKU010', name: 'Nuevo');
      const created = Product(id: 10, sku: 'SKU010', name: 'Nuevo');
      when(() => mockRepo.create(newProduct)).thenAnswer((_) async => created);

      await provider.createProduct(newProduct);

      expect(provider.status, ProductStatus.loaded);
      verify(() => mockRepo.create(newProduct)).called(1);
    });

    test('debe setear error si create falla', () async {
      when(
        () => mockRepo.create(any()),
      ).thenThrow(const ApiException('SKU duplicado', 409));

      await provider.createProduct(
        const Product(id: 0, sku: 'SKU001', name: 'Test'),
      );

      expect(provider.status, ProductStatus.error);
      expect(provider.error, isNotNull);
    });
  });

  group('updateProduct', () {
    test('debe actualizar producto exitosamente', () async {
      const product = Product(id: 1, sku: 'SKU001', name: 'Editado');

      await provider.updateProduct(product);

      expect(provider.status, ProductStatus.loaded);
      verify(() => mockRepo.update(product)).called(1);
    });
  });

  group('deleteProduct', () {
    test('debe eliminar producto con id correcto', () async {
      const id = 5;

      await provider.deleteProduct(id);

      expect(provider.status, ProductStatus.loaded);
      verify(() => mockRepo.delete(id)).called(1);
    });
  });

  group('reactivateProduct', () {
    test('debe reactivar producto con id correcto', () async {
      const id = 3;
      const reactivated = Product(
        id: 3,
        sku: 'SKU003',
        name: 'Reactivated',
        active: true,
      );
      when(() => mockRepo.reactivate(id)).thenAnswer((_) async => reactivated);

      await provider.reactivateProduct(id);

      expect(provider.status, ProductStatus.loaded);
      expect(provider.currentProduct, reactivated);
      verify(() => mockRepo.reactivate(id)).called(1);
    });
  });

  group('ChangeNotifier', () {
    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });

    test('debe notificar listeners durante loadProducts', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadProducts();

      expect(notifyCount, greaterThan(0));
    });
  });
}
