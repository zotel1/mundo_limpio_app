// Pruebas unitarias para SalesRepositoryImpl — offline-aware.
//
// Verifica que el repositorio orquesta online/offline correctamente:
// - Online: delega en SalesApi + cachea resultados en Drift DAOs
// - Offline: lee desde caché local, guarda borradores de ventas
// - Batch TTL: lotes cacheados offline expiran a los 5 minutos
// - Draft: confirmDraft lee borrador, llama API, marca confirmado
//
// TDD: RED — tests escritos antes de la implementación offline-aware

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/connectivity/connectivity_service.dart';
import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/drift/daos/batch_cache_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/draft_sale_dao.dart';
import 'package:mundo_limpio_app/core/drift/daos/product_cache_dao.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/data/api/sales_api.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/data/repository/sales_repository_impl.dart';

// ─── Mocks ──────────────────────────────────────────────────────────────────

class MockSalesApi extends Mock implements SalesApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockProductCacheDao extends Mock implements ProductCacheDao {}

class MockBatchCacheDao extends Mock implements BatchCacheDao {}

class MockDraftSaleDao extends Mock implements DraftSaleDao {}

// ─── Helpers ────────────────────────────────────────────────────────────────

void main() {
  late MockSalesApi mockSalesApi;
  late MockConnectivityService mockConnectivity;
  late MockProductCacheDao mockProductCacheDao;
  late MockBatchCacheDao mockBatchCacheDao;
  late MockDraftSaleDao mockDraftSaleDao;
  late SalesRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(SaleRequest(productId: 0, quantity: 0));
    registerFallbackValue(
      DraftSalesCompanion.insert(
        productId: 0,
        productName: '',
        batchId: 0,
        quantity: 0,
        unitPrice: 0,
      ),
    );
    registerFallbackValue(<ProductCacheData>[]);
    registerFallbackValue(<BatchCacheData>[]);
  });

  setUp(() {
    mockSalesApi = MockSalesApi();
    mockConnectivity = MockConnectivityService();
    mockProductCacheDao = MockProductCacheDao();
    mockBatchCacheDao = MockBatchCacheDao();
    mockDraftSaleDao = MockDraftSaleDao();

    // Default: online
    when(() => mockConnectivity.isOnline).thenReturn(true);

    repository = SalesRepositoryImpl(
      salesApi: mockSalesApi,
      connectivity: mockConnectivity,
      productCacheDao: mockProductCacheDao,
      batchCacheDao: mockBatchCacheDao,
      draftSaleDao: mockDraftSaleDao,
    );
  });

  // ─── Helper: configura estado online/offline ──────────────────────────
  void setOnline() {
    when(() => mockConnectivity.isOnline).thenReturn(true);
  }

  void setOffline() {
    when(() => mockConnectivity.isOnline).thenReturn(false);
  }

  // ══════════════════════════════════════════════════════════════════════
  // getProducts
  // ══════════════════════════════════════════════════════════════════════

  group('getProducts — online', () {
    test(
      'debe llamar SalesApi, cachear en ProductCacheDao y retornar',
      () async {
        // Arrange
        setOnline();
        final products = [
          const ProductResponse(id: 1, name: 'Producto A'),
          const ProductResponse(id: 2, name: 'Producto B'),
        ];
        when(
          () => mockSalesApi.getProducts(),
        ).thenAnswer((_) async => products);
        when(
          () => mockProductCacheDao.upsertAll(any()),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.getProducts();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, 1);
        expect(result[0].name, 'Producto A');
        verify(() => mockSalesApi.getProducts()).called(1);
        verify(() => mockProductCacheDao.upsertAll(any())).called(1);
      },
    );

    test('debe propagar ApiException cuando SalesApi falla', () async {
      // Arrange
      setOnline();
      when(
        () => mockSalesApi.getProducts(),
      ).thenThrow(const ApiException('Error de red', 0));

      // Act & Assert
      expect(() => repository.getProducts(), throwsA(isA<ApiException>()));
    });
  });

  group('getProducts — offline', () {
    test('debe leer desde ProductCacheDao cuando hay caché', () async {
      // Arrange
      setOffline();
      final cached = [
        ProductCacheData(
          id: 1,
          name: 'Cache A',
          updatedAt: DateTime.now(),
          active: true,
        ),
        ProductCacheData(
          id: 2,
          name: 'Cache B',
          updatedAt: DateTime.now(),
          active: true,
        ),
      ];
      when(() => mockProductCacheDao.getAll()).thenAnswer((_) async => cached);

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result, hasLength(2));
      expect(result[0].id, 1);
      expect(result[0].name, 'Cache A');
      verifyNever(() => mockSalesApi.getProducts());
      verify(() => mockProductCacheDao.getAll()).called(1);
    });

    test('debe retornar lista vacía cuando el caché está vacío', () async {
      // Arrange
      setOffline();
      when(() => mockProductCacheDao.getAll()).thenAnswer((_) async => []);

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result, isEmpty);
      verifyNever(() => mockSalesApi.getProducts());
    });

    test('no debe cachear al leer offline', () async {
      // Arrange
      setOffline();
      when(() => mockProductCacheDao.getAll()).thenAnswer((_) async => []);

      // Act
      await repository.getProducts();

      // Assert: upsertAll NUNCA se llama offline
      verifyNever(() => mockProductCacheDao.upsertAll(any()));
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // getBatchesByProduct
  // ══════════════════════════════════════════════════════════════════════

  group('getBatchesByProduct — online', () {
    test(
      'debe llamar SalesApi, limpiar caché viejo, cachear y retornar',
      () async {
        // Arrange
        setOnline();
        const productId = 42;
        final batches = [
          const ProductionBatchResponse(
            id: 1,
            productId: productId,
            currentStock: 100.0,
          ),
          const ProductionBatchResponse(
            id: 2,
            productId: productId,
            currentStock: 50.0,
          ),
        ];
        when(
          () => mockSalesApi.getBatchesByProduct(productId),
        ).thenAnswer((_) async => batches);
        when(
          () => mockBatchCacheDao.deleteByProductId(productId),
        ).thenAnswer((_) async {});
        when(() => mockBatchCacheDao.upsertAll(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.getBatchesByProduct(productId);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].currentStock, 100.0);
        verify(() => mockSalesApi.getBatchesByProduct(productId)).called(1);
        verify(() => mockBatchCacheDao.deleteByProductId(productId)).called(1);
        verify(() => mockBatchCacheDao.upsertAll(any())).called(1);
      },
    );

    test('debe propagar ApiException cuando SalesApi falla', () async {
      // Arrange
      setOnline();
      when(
        () => mockSalesApi.getBatchesByProduct(any()),
      ).thenThrow(const ApiException('Producto no encontrado', 404));

      // Act & Assert
      expect(
        () => repository.getBatchesByProduct(1),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getBatchesByProduct — offline', () {
    test('debe leer desde BatchCacheDao cuando el caché está fresco', () async {
      // Arrange
      setOffline();
      const productId = 42;
      final cached = [
        BatchCacheData(
          id: 1,
          productId: productId,
          currentStock: 100.0,
          updatedAt: DateTime.now(),
        ),
        BatchCacheData(
          id: 2,
          productId: productId,
          currentStock: 50.0,
          updatedAt: DateTime.now(),
        ),
      ];
      when(
        () => mockBatchCacheDao.getByProductId(productId),
      ).thenAnswer((_) async => cached);

      // Act
      final result = await repository.getBatchesByProduct(productId);

      // Assert
      expect(result, hasLength(2));
      expect(result[0].currentStock, 100.0);
      verifyNever(() => mockSalesApi.getBatchesByProduct(any()));
    });

    test('debe retornar [] cuando el caché expiró (TTL > 5 min)', () async {
      // Arrange
      setOffline();
      const productId = 42;
      final expired = [
        BatchCacheData(
          id: 1,
          productId: productId,
          currentStock: 100.0,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
      ];
      when(
        () => mockBatchCacheDao.getByProductId(productId),
      ).thenAnswer((_) async => expired);

      // Act
      final result = await repository.getBatchesByProduct(productId);

      // Assert: TTL expirado, retorna vacío
      expect(result, isEmpty);
      verifyNever(() => mockSalesApi.getBatchesByProduct(any()));
    });

    test('debe retornar [] cuando el caché está vacío', () async {
      // Arrange
      setOffline();
      when(
        () => mockBatchCacheDao.getByProductId(42),
      ).thenAnswer((_) async => []);

      // Act
      final result = await repository.getBatchesByProduct(42);

      // Assert
      expect(result, isEmpty);
    });

    test(
      'debe retornar datos cuando el caché tiene exactamente 5 min (límite)',
      () async {
        // Arrange
        setOffline();
        const productId = 42;
        final justFresh = [
          BatchCacheData(
            id: 1,
            productId: productId,
            currentStock: 75.0,
            updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ];
        when(
          () => mockBatchCacheDao.getByProductId(productId),
        ).thenAnswer((_) async => justFresh);

        // Act
        final result = await repository.getBatchesByProduct(productId);

        // Assert: 5 min exactos → aún fresco
        expect(result, hasLength(1));
        expect(result[0].currentStock, 75.0);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════
  // createSale
  // ══════════════════════════════════════════════════════════════════════

  group('createSale — online', () {
    test('debe llamar SalesApi.createSale y retornar respuesta', () async {
      // Arrange
      setOnline();
      final request = SaleRequest(productId: 1, quantity: 30.0);
      final expectedResponse = SaleResponse(
        id: 1,
        totalAmount: 375.00,
        createdAt: DateTime(2026, 5, 10, 10, 30, 0),
        items: const [
          SaleItemResponse(
            batchId: 42,
            productId: 1,
            productName: 'Test Product',
            quantity: 30.0,
            unitPrice: 150.00,
            unitCost: 100.00,
          ),
        ],
      );
      when(
        () => mockSalesApi.createSale(request),
      ).thenAnswer((_) async => expectedResponse);

      // Act
      final result = await repository.createSale(request);

      // Assert
      expect(result.id, 1);
      expect(result.total, 375.00);
      verify(() => mockSalesApi.createSale(request)).called(1);
      verifyNever(() => mockDraftSaleDao.insert(any()));
    });

    test('debe propagar ApiException cuando SalesApi falla', () async {
      // Arrange
      setOnline();
      final request = SaleRequest(productId: 1, quantity: 100.0);
      when(
        () => mockSalesApi.createSale(request),
      ).thenThrow(const ApiException('Stock insuficiente', 400));

      // Act & Assert
      expect(
        () => repository.createSale(request),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('createSale — offline', () {
    test(
      'debe guardar borrador en DraftSaleDao y retornar SaleResponse.draft()',
      () async {
        // Arrange
        setOffline();
        final request = SaleRequest(productId: 42, quantity: 15.0);
        when(() => mockDraftSaleDao.insert(any())).thenAnswer((_) async => 1);

        // Act
        final result = await repository.createSale(request);

        // Assert
        expect(result.id, -1);
        expect(result.total, 0.0);
        expect(result.items, isEmpty);
        verify(() => mockDraftSaleDao.insert(any())).called(1);
        verifyNever(() => mockSalesApi.createSale(any()));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════
  // confirmDraft
  // ══════════════════════════════════════════════════════════════════════

  group('confirmDraft', () {
    test(
      'debe leer borrador, llamar API, marcar confirmado y retornar respuesta',
      () async {
        // Arrange
        final draft = DraftSale(
          id: 5,
          productId: 42,
          productName: 'Producto Test',
          batchId: 10,
          quantity: 30.0,
          unitPrice: 150.0,
          status: 'draft',
          createdAt: DateTime(2026, 5, 10),
        );
        final apiResponse = SaleResponse(
          id: 99,
          totalAmount: 4500.00,
          createdAt: DateTime(2026, 5, 10, 12, 0, 0),
          items: const [
            SaleItemResponse(
              batchId: 10,
              productId: 1,
              productName: 'Test Product',
              quantity: 30.0,
              unitPrice: 150.00,
              unitCost: 100.00,
            ),
          ],
        );

        when(() => mockDraftSaleDao.getById(5)).thenAnswer((_) async => draft);
        when(
          () => mockSalesApi.createSale(any()),
        ).thenAnswer((_) async => apiResponse);
        when(
          () => mockDraftSaleDao.updateStatus(5, 'confirmed'),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.confirmDraft(5);

        // Assert
        expect(result.id, 99);
        expect(result.total, 4500.00);
        verify(() => mockDraftSaleDao.getById(5)).called(1);
        verify(() => mockSalesApi.createSale(any())).called(1);
        verify(() => mockDraftSaleDao.updateStatus(5, 'confirmed')).called(1);
      },
    );

    test(
      'debe mantener status draft cuando API falla con ApiException',
      () async {
        // Arrange
        final draft = DraftSale(
          id: 7,
          productId: 1,
          productName: 'Test',
          batchId: 1,
          quantity: 10.0,
          unitPrice: 100.0,
          status: 'draft',
          createdAt: DateTime(2026),
        );

        when(() => mockDraftSaleDao.getById(7)).thenAnswer((_) async => draft);
        when(
          () => mockSalesApi.createSale(any()),
        ).thenThrow(const ApiException('Stock insuficiente', 400));

        // Act & Assert
        expect(() => repository.confirmDraft(7), throwsA(isA<ApiException>()));
        // NUNCA se marca como confirmado
        verifyNever(() => mockDraftSaleDao.updateStatus(any(), 'confirmed'));
        // El draft se leyó correctamente
        verify(() => mockDraftSaleDao.getById(7)).called(1);
      },
    );

    test('debe propagar la excepción cuando getById falla', () async {
      // Arrange
      when(
        () => mockDraftSaleDao.getById(99),
      ).thenThrow(const ApiException('Borrador no encontrado', 404));

      // Act & Assert
      expect(() => repository.confirmDraft(99), throwsA(isA<ApiException>()));
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // getDrafts
  // ══════════════════════════════════════════════════════════════════════

  group('getDrafts', () {
    test('debe retornar todos los borradores con status draft', () async {
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
      when(
        () => mockDraftSaleDao.getAllByStatus('draft'),
      ).thenAnswer((_) async => drafts);

      // Act
      final result = await repository.getDrafts();

      // Assert
      expect(result, hasLength(2));
      expect(result[0].productName, 'P1');
      expect(result[1].productName, 'P2');
      verify(() => mockDraftSaleDao.getAllByStatus('draft')).called(1);
    });

    test('debe retornar lista vacía cuando no hay borradores', () async {
      // Arrange
      when(
        () => mockDraftSaleDao.getAllByStatus('draft'),
      ).thenAnswer((_) async => []);

      // Act
      final result = await repository.getDrafts();

      // Assert
      expect(result, isEmpty);
    });
  });
}
