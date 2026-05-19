// Pruebas unitarias para SalesProvider.
//
// Verifica la máquina de estados del flujo de creación de venta:
//   idle → loadProducts() → loading → productsLoaded → loadStock(id) → loading → stockLoaded → createSale(qty) → loading → success → reset() → idle
//   Cualquier error → error → clearError() → idle
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_provider.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

void main() {
  late MockSalesRepository mockRepo;
  late SalesProvider provider;

  const productA = ProductResponse(id: 1, name: 'Producto A');
  const productB = ProductResponse(id: 2, name: 'Producto B');

  setUpAll(() {
    registerFallbackValue(const SaleRequest(productId: 0, quantity: 0));
  });

  setUp(() {
    mockRepo = MockSalesRepository();
    provider = SalesProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Estado inicial
  // ──────────────────────────────────────────────
  group('estado inicial', () {
    test('status debe ser idle', () {
      expect(provider.status, SalesStatus.idle);
    });

    test('products debe ser lista vacía', () {
      expect(provider.products, isEmpty);
    });

    test('batches debe ser lista vacía', () {
      expect(provider.batches, isEmpty);
    });

    test('selectedProductId debe ser null', () {
      expect(provider.selectedProductId, isNull);
    });

    test('errorMessage debe ser null', () {
      expect(provider.errorMessage, isNull);
    });

    test('lastSale debe ser null', () {
      expect(provider.lastSale, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // loadProducts
  // ──────────────────────────────────────────────
  group('loadProducts', () {
    test(
      'debe transitar idle → loading → productsLoaded y exponer lista (R4-1)',
      () async {
        // Arrange
        when(
          () => mockRepo.getProducts(),
        ).thenAnswer((_) async => [productA, productB]);

        // Act
        await provider.loadProducts();

        // Assert
        expect(provider.status, SalesStatus.productsLoaded);
        expect(provider.products, hasLength(2));
        expect(provider.products[0].name, 'Producto A');
        expect(provider.products[1].id, 2);
      },
    );

    test(
      'debe fallar con error cuando getProducts lanza ApiException (R4-2)',
      () async {
        // Arrange
        when(
          () => mockRepo.getProducts(),
        ).thenThrow(const ApiException('Error al cargar productos', 500));

        // Act
        await provider.loadProducts();

        // Assert
        expect(provider.status, SalesStatus.error);
        expect(provider.errorMessage, contains('Error al cargar productos'));
      },
    );

    test('debe limpiar errorMessage antes de cargar (triangulación)', () async {
      // Arrange: fallo primero
      when(
        () => mockRepo.getProducts(),
      ).thenThrow(const ApiException('Error previo', 500));
      await provider.loadProducts();
      expect(provider.errorMessage, isNotNull);

      // Arrange: éxito después
      when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);

      // Act
      await provider.loadProducts();

      // Assert
      expect(provider.status, SalesStatus.productsLoaded);
      expect(provider.errorMessage, isNull);
    });

    test(
      'debe retornar lista vacía cuando no hay productos (triangulación)',
      () async {
        // Arrange
        when(() => mockRepo.getProducts()).thenAnswer((_) async => []);

        // Act
        await provider.loadProducts();

        // Assert
        expect(provider.status, SalesStatus.productsLoaded);
        expect(provider.products, isEmpty);
      },
    );

    test(
      'debe manejar errores genéricos en loadProducts (no ApiException)',
      () async {
        // Arrange
        when(
          () => mockRepo.getProducts(),
        ).thenThrow(Exception('Algo salió mal'));

        // Act
        await provider.loadProducts();

        // Assert
        expect(provider.status, SalesStatus.error);
        expect(provider.errorMessage, isNotNull);
      },
    );
  });

  // ──────────────────────────────────────────────
  // loadStock
  // ──────────────────────────────────────────────
  group('loadStock', () {
    test(
      'debe transitar productsLoaded → loading → stockLoaded y exponer batches (R4-3)',
      () async {
        // Arrange: productsLoaded primero
        when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
        await provider.loadProducts();

        final batches = [
          const ProductionBatchResponse(
            id: 1,
            productId: 1,
            currentStock: 100.0,
          ),
          const ProductionBatchResponse(
            id: 2,
            productId: 1,
            currentStock: 50.0,
          ),
        ];
        when(
          () => mockRepo.getBatchesByProduct(1),
        ).thenAnswer((_) async => batches);

        // Act
        await provider.loadStock(1);

        // Assert
        expect(provider.status, SalesStatus.stockLoaded);
        expect(provider.selectedProductId, 1);
        expect(provider.batches, hasLength(2));
        expect(provider.batches[0].currentStock, 100.0);
        expect(provider.batches[1].currentStock, 50.0);
      },
    );

    test(
      'debe fallar con error cuando getBatchesByProduct lanza ApiException',
      () async {
        // Arrange
        when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
        await provider.loadProducts();

        when(
          () => mockRepo.getBatchesByProduct(1),
        ).thenThrow(const ApiException('Producto no encontrado', 404));

        // Act
        await provider.loadStock(1);

        // Assert
        expect(provider.status, SalesStatus.error);
        expect(provider.errorMessage, contains('Producto no encontrado'));
        // selectedProductId se setea ANTES del error
        expect(provider.selectedProductId, 1);
      },
    );

    test(
      'debe manejar errores genéricos en loadStock (triangulación)',
      () async {
        // Arrange
        when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
        await provider.loadProducts();

        when(
          () => mockRepo.getBatchesByProduct(1),
        ).thenThrow(Exception('Error de red'));

        // Act
        await provider.loadStock(1);

        // Assert
        expect(provider.status, SalesStatus.error);
        expect(provider.errorMessage, isNotNull);
      },
    );
  });

  // ──────────────────────────────────────────────
  // createSale
  // ──────────────────────────────────────────────
  group('createSale', () {
    // Helper: pone el provider en stockLoaded
    Future<void> setupLoaded() async {
      when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
      await provider.loadProducts();

      when(() => mockRepo.getBatchesByProduct(1)).thenAnswer(
        (_) async => [
          const ProductionBatchResponse(
            id: 1,
            productId: 1,
            currentStock: 100.0,
          ),
        ],
      );
      await provider.loadStock(1);
    }

    test(
      'debe transitar stockLoaded → loading → success y exponer SaleResponse (R4-4)',
      () async {
        // Arrange
        await setupLoaded();

        final response = SaleResponse(
          id: 1,
          totalAmount: 375.00,
          createdAt: DateTime(2026, 5, 10, 10, 30, 0),
          items: const [
            SaleItemResponse(
              batchId: 42,
              quantity: 30.0,
              unitPrice: 150.00,
              unitCost: 100.00,
            ),
          ],
        );
        when(
          () => mockRepo.createSale(any()),
        ).thenAnswer((_) async => response);

        // Act
        await provider.createSale(30.0);

        // Assert
        expect(provider.status, SalesStatus.success);
        expect(provider.lastSale, isNotNull);
        expect(provider.lastSale!.id, 1);
        expect(provider.lastSale!.totalAmount, 375.00);
        expect(provider.lastSale!.items, hasLength(1));
      },
    );

    test(
      'debe fallar con error cuando createSale lanza ApiException (R4-5)',
      () async {
        // Arrange
        await setupLoaded();

        when(
          () => mockRepo.createSale(any()),
        ).thenThrow(const ApiException('Stock insuficiente', 400));

        // Act
        await provider.createSale(100.0);

        // Assert
        expect(provider.status, SalesStatus.error);
        expect(provider.errorMessage, contains('Stock insuficiente'));
      },
    );

    test(
      'debe crear SaleRequest con los campos correctos (triangulación)',
      () async {
        // Arrange
        await setupLoaded();
        when(() => mockRepo.createSale(any())).thenAnswer(
          (_) async => SaleResponse(
            id: 1,
            totalAmount: 100,
            createdAt: DateTime(2026),
            items: [],
          ),
        );

        // Act
        await provider.createSale(30.0);

        // Assert: verifica que se llamó con un SaleRequest válido
        verify(
          () => mockRepo.createSale(any(that: isA<SaleRequest>())),
        ).called(1);
        expect(provider.status, SalesStatus.success);
      },
    );

    test(
      'no debe hacer nada si status no es stockLoaded (precondición)',
      () async {
        // Arrange: solo productsLoaded, no stock
        when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
        await provider.loadProducts();

        // Act
        await provider.createSale(30.0);

        // Assert: estado no cambia
        expect(provider.status, SalesStatus.productsLoaded);
        expect(provider.lastSale, isNull);
        verifyNever(() => mockRepo.createSale(any()));
      },
    );
  });

  // ──────────────────────────────────────────────
  // reset
  // ──────────────────────────────────────────────
  group('reset', () {
    test('debe volver a idle con todos los campos limpios (R4-6)', () async {
      // Arrange: flujo completo exitoso
      when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
      await provider.loadProducts();

      when(() => mockRepo.getBatchesByProduct(1)).thenAnswer(
        (_) async => [
          const ProductionBatchResponse(
            id: 1,
            productId: 1,
            currentStock: 100.0,
          ),
        ],
      );
      await provider.loadStock(1);

      when(() => mockRepo.createSale(any())).thenAnswer(
        (_) async => SaleResponse(
          id: 1,
          totalAmount: 100,
          createdAt: DateTime(2026),
          items: [],
        ),
      );
      await provider.createSale(30.0);
      expect(provider.status, SalesStatus.success);

      // Act
      provider.reset();

      // Assert
      expect(provider.status, SalesStatus.idle);
      expect(provider.products, isEmpty);
      expect(provider.batches, isEmpty);
      expect(provider.selectedProductId, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.lastSale, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // stockTotal
  // ──────────────────────────────────────────────
  group('stockTotal', () {
    test(
      'debe sumar currentStock de todos los batches cuando hay lotes',
      () async {
        // Arrange
        when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
        await provider.loadProducts();

        when(() => mockRepo.getBatchesByProduct(1)).thenAnswer(
          (_) async => [
            const ProductionBatchResponse(
              id: 1,
              productId: 1,
              currentStock: 100.0,
            ),
            const ProductionBatchResponse(
              id: 2,
              productId: 1,
              currentStock: 50.0,
            ),
          ],
        );
        await provider.loadStock(1);

        // Assert
        expect(provider.stockTotal, 150.0);
      },
    );

    test('debe ser 0 cuando no hay batches', () async {
      // Arrange: estado inicial sin lotes cargados

      // Assert
      expect(provider.stockTotal, 0.0);
    });
  });

  // ──────────────────────────────────────────────
  // clearError
  // ──────────────────────────────────────────────
  group('clearError', () {
    test('debe setear status idle y null errorMessage', () async {
      // Arrange: forzar error
      when(
        () => mockRepo.getProducts(),
      ).thenThrow(const ApiException('Error', 500));
      await provider.loadProducts();
      expect(provider.status, SalesStatus.error);

      // Act
      provider.clearError();

      // Assert
      expect(provider.status, SalesStatus.idle);
      expect(provider.errorMessage, isNull);
    });

    test('no debe fallar si no hay error previo', () {
      // Act (sin error previo)
      provider.clearError();

      // Assert
      expect(provider.status, SalesStatus.idle);
      expect(provider.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // ChangeNotifier
  // ──────────────────────────────────────────────
  group('ChangeNotifier', () {
    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });

    test('debe llamar notifyListeners durante loadProducts', () async {
      when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadProducts();

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante loadStock', () async {
      when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
      await provider.loadProducts();
      when(() => mockRepo.getBatchesByProduct(1)).thenAnswer((_) async => []);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadStock(1);

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante createSale', () async {
      when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
      await provider.loadProducts();
      when(() => mockRepo.getBatchesByProduct(1)).thenAnswer((_) async => []);
      await provider.loadStock(1);
      when(() => mockRepo.createSale(any())).thenAnswer(
        (_) async => SaleResponse(
          id: 1,
          totalAmount: 100,
          createdAt: DateTime(2026),
          items: [],
        ),
      );

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.createSale(30.0);

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners en reset', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reset();

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners en clearError', () async {
      when(
        () => mockRepo.getProducts(),
      ).thenThrow(const ApiException('Error', 500));
      await provider.loadProducts();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();

      expect(notifyCount, greaterThan(0));
    });
  });

  // ──────────────────────────────────────────────────────────────
  // loadDrafts — TDD: RED
  // ──────────────────────────────────────────────────────────────
  group('loadDrafts', () {
    test('debe poblar la lista de drafts desde el repositorio', () async {
      // Arrange
      final drafts = [
        DraftSale(
          id: 1,
          productId: 10,
          productName: 'P1',
          batchId: 1,
          quantity: 5.0,
          unitPrice: 100.0,
          status: 'draft',
          createdAt: DateTime(2026, 5, 10),
        ),
        DraftSale(
          id: 2,
          productId: 20,
          productName: 'P2',
          batchId: 2,
          quantity: 3.0,
          unitPrice: 200.0,
          status: 'draft',
          createdAt: DateTime(2026, 5, 11),
        ),
      ];
      when(() => mockRepo.getDrafts()).thenAnswer((_) async => drafts);

      // Act
      await provider.loadDrafts();

      // Assert
      expect(provider.drafts, hasLength(2));
      expect(provider.drafts[0].productName, 'P1');
      expect(provider.drafts[1].productName, 'P2');
    });

    test('debe retornar lista vacía cuando no hay borradores', () async {
      // Arrange
      when(() => mockRepo.getDrafts()).thenAnswer((_) async => []);

      // Act
      await provider.loadDrafts();

      // Assert
      expect(provider.drafts, isEmpty);
    });

    test('debe manejar ApiException al cargar drafts', () async {
      // Arrange
      when(
        () => mockRepo.getDrafts(),
      ).thenThrow(const ApiException('Error al cargar', 500));

      // Act
      await provider.loadDrafts();

      // Assert
      expect(provider.status, SalesStatus.error);
      expect(provider.errorMessage, contains('Error al cargar'));
    });
  });

  // ──────────────────────────────────────────────────────────────
  // confirmDraft — TDD: RED
  // ──────────────────────────────────────────────────────────────
  group('confirmDraft', () {
    test(
      'debe llamar repository.confirmDraft y actualizar estado a success',
      () async {
        // Arrange
        final response = SaleResponse(
          id: 99,
          totalAmount: 1500.00,
          createdAt: DateTime(2026, 5, 10, 12, 0, 0),
          items: const [
            SaleItemResponse(
              batchId: 10,
              quantity: 10.0,
              unitPrice: 150.00,
              unitCost: 100.00,
            ),
          ],
        );
        when(() => mockRepo.confirmDraft(5)).thenAnswer((_) async => response);

        // Act
        await provider.confirmDraft(5);

        // Assert
        expect(provider.status, SalesStatus.success);
        expect(provider.lastSale, isNotNull);
        expect(provider.lastSale!.id, 99);
        verify(() => mockRepo.confirmDraft(5)).called(1);
      },
    );

    test('debe setear error cuando confirmDraft lanza ApiException', () async {
      // Arrange
      when(
        () => mockRepo.confirmDraft(7),
      ).thenThrow(const ApiException('Stock insuficiente', 400));

      // Act
      await provider.confirmDraft(7);

      // Assert
      expect(provider.status, SalesStatus.error);
      expect(provider.errorMessage, contains('Stock insuficiente'));
    });

    test('debe manejar errores genéricos en confirmDraft', () async {
      // Arrange
      when(
        () => mockRepo.confirmDraft(1),
      ).thenThrow(Exception('Error inesperado'));

      // Act
      await provider.confirmDraft(1);

      // Assert
      expect(provider.status, SalesStatus.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // createSale con respuesta draft — TDD: RED
  // ──────────────────────────────────────────────────────────────
  group('createSale — respuesta draft (offline)', () {
    test(
      'debe setear status success cuando createSale retorna draft (id=-1)',
      () async {
        // Arrange: poner provider en stockLoaded
        when(() => mockRepo.getProducts()).thenAnswer((_) async => [productA]);
        await provider.loadProducts();
        when(() => mockRepo.getBatchesByProduct(1)).thenAnswer(
          (_) async => [
            const ProductionBatchResponse(
              id: 1,
              productId: 1,
              currentStock: 100.0,
            ),
          ],
        );
        await provider.loadStock(1);

        final draftResponse = SaleResponse.draft();
        when(
          () => mockRepo.createSale(any()),
        ).thenAnswer((_) async => draftResponse);

        // Act
        await provider.createSale(15.0);

        // Assert: aunque es borrador, el status es success
        expect(provider.status, SalesStatus.success);
        expect(provider.lastSale, isNotNull);
        expect(provider.lastSale!.id, -1);
      },
    );
  });

  // ──────────────────────────────────────────────────────────────
  // reset incluye drafts — TDD: RED
  // ──────────────────────────────────────────────────────────────
  group('reset — incluye drafts', () {
    test('debe limpiar drafts al hacer reset', () async {
      // Arrange: poblar drafts
      final drafts = [
        DraftSale(
          id: 1,
          productId: 10,
          productName: 'P1',
          batchId: 1,
          quantity: 5.0,
          unitPrice: 100.0,
          status: 'draft',
          createdAt: DateTime(2026),
        ),
      ];
      when(() => mockRepo.getDrafts()).thenAnswer((_) async => drafts);
      await provider.loadDrafts();
      expect(provider.drafts, isNotEmpty);

      // Act
      provider.reset();

      // Assert
      expect(provider.drafts, isEmpty);
    });
  });
}
