// TDD: RED — test escrito antes que la implementación
//
// Pruebas unitarias para BulkProductProvider.
//
// Verifica:
// - Estado inicial correcto
// - getBulkProducts carga lista y maneja errores
// - createBulkProduct, updateBulkProduct, deleteBulkProduct exitosos
// - ChangeNotifier notifica listeners

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';

class MockBulkProductRepository extends Mock implements IBulkProductRepository {}

void main() {
  late MockBulkProductRepository mockRepo;
  late BulkProductProvider provider;

  setUpAll(() {
    registerFallbackValue(
      const BulkProduct(id: 0, name: '', unitOfMeasure: '', stock: 0.0),
    );
  });

  setUp(() {
    mockRepo = MockBulkProductRepository();
    provider = BulkProductProvider(mockRepo);

    // Stubs por defecto
    when(() => mockRepo.getBulkProducts()).thenAnswer((_) async => []);
    when(() => mockRepo.createBulkProduct(any())).thenAnswer(
      (_) async =>
          const BulkProduct(id: 1, name: 'Test', unitOfMeasure: 'L', stock: 10.0),
    );
    when(() => mockRepo.updateBulkProduct(any())).thenAnswer(
      (_) async =>
          const BulkProduct(id: 1, name: 'Updated', unitOfMeasure: 'L', stock: 20.0),
    );
    when(() => mockRepo.deleteBulkProduct(any())).thenAnswer((_) async {});
  });

  group('estado inicial', () {
    test('debe iniciar con status initial', () {
      expect(provider.status, BulkProductStatus.initial);
    });

    test('debe iniciar sin error', () {
      expect(provider.error, isNull);
    });

    test('isLoading debe ser false al iniciar', () {
      expect(provider.isLoading, isFalse);
    });

    test('debe iniciar con lista vacía', () {
      expect(provider.bulkProducts, isEmpty);
    });
  });

  group('getBulkProducts', () {
    test('debe cargar lista y setear status loaded', () async {
      final products = [
        const BulkProduct(id: 1, name: 'Alcohol', unitOfMeasure: 'L', stock: 10.0),
        const BulkProduct(id: 2, name: 'Agua', unitOfMeasure: 'L', stock: 20.0),
      ];
      when(() => mockRepo.getBulkProducts()).thenAnswer((_) async => products);

      await provider.getBulkProducts();

      expect(provider.status, BulkProductStatus.loaded);
      expect(provider.bulkProducts, products);
      expect(provider.isLoading, isFalse);
    });

    test('debe cargar lista vacía y setear status loaded', () async {
      when(() => mockRepo.getBulkProducts()).thenAnswer((_) async => []);

      await provider.getBulkProducts();

      expect(provider.status, BulkProductStatus.loaded);
      expect(provider.bulkProducts, isEmpty);
    });

    test('debe setear error cuando falla con ApiException', () async {
      when(() => mockRepo.getBulkProducts()).thenThrow(
        const ApiException('Error de red', 500),
      );

      await provider.getBulkProducts();

      expect(provider.status, BulkProductStatus.error);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
    });
  });

  group('createBulkProduct', () {
    test('debe crear producto exitosamente', () async {
      final newProduct =
          const BulkProduct(id: 0, name: 'Nuevo', unitOfMeasure: 'kg', stock: 5.0);
      final created =
          const BulkProduct(id: 3, name: 'Nuevo', unitOfMeasure: 'kg', stock: 5.0);
      when(() => mockRepo.createBulkProduct(newProduct))
          .thenAnswer((_) async => created);

      await provider.createBulkProduct(newProduct);

      expect(provider.status, BulkProductStatus.loaded);
      verify(() => mockRepo.createBulkProduct(newProduct)).called(1);
    });
  });

  group('updateBulkProduct', () {
    test('debe actualizar producto exitosamente', () async {
      final product =
          const BulkProduct(id: 1, name: 'Editado', unitOfMeasure: 'L', stock: 15.0);

      await provider.updateBulkProduct(product);

      expect(provider.status, BulkProductStatus.loaded);
      verify(() => mockRepo.updateBulkProduct(product)).called(1);
    });
  });

  group('deleteBulkProduct', () {
    test('debe eliminar producto con id correcto', () async {
      const id = 5;

      await provider.deleteBulkProduct(id);

      expect(provider.status, BulkProductStatus.loaded);
      verify(() => mockRepo.deleteBulkProduct(id)).called(1);
    });
  });

  group('ChangeNotifier', () {
    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });

    test('debe notificar listeners durante getBulkProducts', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.getBulkProducts();

      expect(notifyCount, greaterThan(0));
    });
  });
}
