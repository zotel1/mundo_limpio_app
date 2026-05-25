// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/domain/repositories/i_products_repository.dart';

// Mock del repositorio para verificar el contrato de la interfaz
class MockProductsRepository extends Mock implements IProductsRepository {}

void main() {
  late MockProductsRepository mockRepository;

  setUp(() {
    mockRepository = MockProductsRepository();
  });

  group('IProductsRepository', () {
    test('getAll debe retornar List<Product> (solo activos)', () async {
      // Arrange
      final expectedProducts = [
        const Product(id: 1, sku: 'PROD-001', name: 'Jabón', active: true),
        const Product(id: 2, sku: 'PROD-002', name: 'Detergente', active: true),
      ];
      when(
        () => mockRepository.getAll(),
      ).thenAnswer((_) async => expectedProducts);

      // Act
      final result = await mockRepository.getAll();

      // Assert
      expect(result, isA<List<Product>>());
      expect(result, hasLength(2));
      expect(result[0].name, 'Jabón');
      expect(result[1].name, 'Detergente');
    });

    test('getAllProducts debe retornar List<Product> (todos)', () async {
      // Arrange
      final expectedProducts = [
        const Product(id: 1, sku: 'PROD-001', name: 'Jabón', active: true),
        const Product(
          id: 2,
          sku: 'PROD-002',
          name: 'Detergente',
          active: false,
        ),
      ];
      when(
        () => mockRepository.getAllProducts(),
      ).thenAnswer((_) async => expectedProducts);

      // Act
      final result = await mockRepository.getAllProducts();

      // Assert
      expect(result, isA<List<Product>>());
      expect(result, hasLength(2));
      expect(result[0].active, true);
      expect(result[1].active, false);
    });

    test('getById debe retornar un Product por ID', () async {
      // Arrange
      const expectedProduct = Product(
        id: 1,
        sku: 'PROD-001',
        name: 'Jabón',
        active: true,
      );
      when(
        () => mockRepository.getById(1),
      ).thenAnswer((_) async => expectedProduct);

      // Act
      final result = await mockRepository.getById(1);

      // Assert
      expect(result, isA<Product>());
      expect(result.id, 1);
      expect(result.name, 'Jabón');
    });

    test('getBySku debe retornar un Product por SKU', () async {
      // Arrange
      const expectedProduct = Product(
        id: 1,
        sku: 'PROD-001',
        name: 'Jabón',
        active: true,
      );
      when(
        () => mockRepository.getBySku('PROD-001'),
      ).thenAnswer((_) async => expectedProduct);

      // Act
      final result = await mockRepository.getBySku('PROD-001');

      // Assert
      expect(result, isA<Product>());
      expect(result.sku, 'PROD-001');
    });

    test('create debe retornar el Product creado', () async {
      // Arrange
      const newProduct = Product(
        id: 0,
        sku: 'PROD-NEW',
        name: 'Nuevo',
        active: true,
      );
      const createdProduct = Product(
        id: 1,
        sku: 'PROD-NEW',
        name: 'Nuevo',
        active: true,
      );
      when(
        () => mockRepository.create(newProduct),
      ).thenAnswer((_) async => createdProduct);

      // Act
      final result = await mockRepository.create(newProduct);

      // Assert
      expect(result, isA<Product>());
      expect(result.id, 1);
    });

    test('update debe retornar el Product actualizado', () async {
      // Arrange
      const updatedProduct = Product(
        id: 1,
        sku: 'PROD-001',
        name: 'Jabón Modificado',
        active: true,
      );
      when(
        () => mockRepository.update(updatedProduct),
      ).thenAnswer((_) async => updatedProduct);

      // Act
      final result = await mockRepository.update(updatedProduct);

      // Assert
      expect(result, isA<Product>());
      expect(result.name, 'Jabón Modificado');
    });

    test('delete debe completar sin error (soft delete)', () async {
      // Arrange
      when(() => mockRepository.delete(1)).thenAnswer((_) async {});

      // Act
      await mockRepository.delete(1);

      // Assert
      verify(() => mockRepository.delete(1)).called(1);
    });

    test('reactivate debe retornar el Product reactivado', () async {
      // Arrange
      const reactivated = Product(
        id: 1,
        sku: 'PROD-001',
        name: 'Jabón',
        active: true,
      );
      when(
        () => mockRepository.reactivate(1),
      ).thenAnswer((_) async => reactivated);

      // Act
      final result = await mockRepository.reactivate(1);

      // Assert
      expect(result, isA<Product>());
      expect(result.active, true);
    });
  });
}
