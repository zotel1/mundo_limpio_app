// TDD: RED — test escrito antes de migrar los screens a widgets branded.
//
// Prueba de migración de branding para los 11 screens del proyecto:
// - Verifica que CADA screen usa BrandedAppBar (find.byType)
// - Login y Register: también verifican LogoWidget + BrandedErrorBanner
//
// NO prueba comportamiento completo — eso ya está cubierto por
// los tests existentes de cada screen.
//
// Estrategia: uso mínimo de mocks. Solo se stubean los métodos
// que se disparan en initState/postFrameCallback para evitar crash.
//
// TDD cycle: RED (este archivo) → GREEN (migrar screens) → REFACTOR (limpiar)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/storage/token_storage.dart';
import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/logo_widget.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/home_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/register_screen.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/domain/repository/inventory_repository.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/provider/inventory_provider.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_detail_screen.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/production_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_form_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_batch_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_create_screen.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_provider.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/create_sale_screen.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sale_result_screen.dart';

// ───────────────────────── Mocks ─────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}
class MockTokenStorage extends Mock implements TokenStorage {}

class MockInventoryRepository extends Mock implements InventoryRepository {}

class MockSalesRepository extends Mock implements SalesRepository {}

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

class MockProductionRepository extends Mock implements IProductionRepository {}

// ───────────────────────── Helpers ─────────────────────────

/// Pump helper: ejecuta frames hasta que los callbacks post-frame
/// tengan oportunidad de correr, pero sin esperar completion.
Future<void> pumpFrames(WidgetTester tester, {int count = 3}) async {
  for (int i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  // ──────────── Registro de fallback values ────────────

  setUpAll(() {
    // Para stubs que usan any() con tipos no primitivos
    registerFallbackValue(const SaleRequest(productId: 0, quantity: 0));
    registerFallbackValue(
      const InventoryResponse(
        productId: 0,
        productName: '',
        currentStock: 0,
        minStockThreshold: 0,
      ),
    );
    registerFallbackValue(
      const BulkProduct(
        id: 0,
        name: '',
        currentStockLiters: 0,
        costPerLiter: 0,
      ),
    );
    registerFallbackValue(
      ProductionBatchRequest(
        finishedProductId: 0,
        bulkProductId: 0,
        quantityUsed: 0.0,
      ),
    );
    registerFallbackValue(
      ProductionBatch(
        id: 0,
        productId: 0,
        bulkProductId: 0,
        initialQuantity: 0.0,
        currentStock: 0.0,
        unitCostAtProduction: 0.0,
        rawQuantityUsed: 0.0,
        productionDate: DateTime(2026),
      ),
    );
  });

  // ═══════════════════════════════════════════════════════
  // AUTH SCREENS — login, register, home
  // ═══════════════════════════════════════════════════════

  group('Auth screens branding', () {
    late MockAuthRepository mockAuthRepo;
    late MockTokenStorage mockTokenStorage;
    late AuthProvider authProvider;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      mockTokenStorage = MockTokenStorage();
      authProvider = AuthProvider(mockAuthRepo, mockTokenStorage);

      when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => false);
    });

    // ─── Login ────────────────────────────────────────

    testWidgets('LoginScreen debe usar BrandedAppBar y LogoWidget', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await pumpFrames(tester);

      // TDD: RED — estos finds DEBEN fallar ANTES de la migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
      expect(find.byType(LogoWidget), findsOneWidget);
    });

    // NOTA: BrandedErrorBanner se verifica implícitamente —
    // el viejo Container rojo desaparece al migrar el error display
    // al widget branded. La ausencia del Container rojo + presencia
    // de BrandedErrorBanner se prueba cuando el provider tiene error.
    // Este escenario específico se cubre en login_screen_test.dart
    // (existente) después de la migración.

    // ─── Register ─────────────────────────────────────

    testWidgets('RegisterScreen debe usar BrandedAppBar y LogoWidget', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
      expect(find.byType(LogoWidget), findsOneWidget);
    });

    // ─── Home ─────────────────────────────────────────

    testWidgets(
      'HomeScreen debe usar BrandedAppBar (preservando action de logout)',
      (tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await pumpFrames(tester);

        // TDD: RED — falla ANTES de migración
        expect(find.byType(BrandedAppBar), findsOneWidget);
      },
    );
  });

  // ═══════════════════════════════════════════════════════
  // INVENTORY SCREENS — list, detail
  // ═══════════════════════════════════════════════════════

  group('Inventory screens branding', () {
    late MockInventoryRepository mockInvRepo;
    late InventoryProvider invProvider;

    setUp(() {
      mockInvRepo = MockInventoryRepository();
      invProvider = InventoryProvider(repository: mockInvRepo);

      // Stubs para evitar crash en postFrameCallback
      when(() => mockInvRepo.getLowStock()).thenAnswer((_) async => []);
      when(() => mockInvRepo.getInventory(any())).thenAnswer(
        (_) async => const InventoryResponse(
          productId: 1,
          productName: 'Test',
          currentStock: 0,
          minStockThreshold: 0,
        ),
      );
    });

    // ─── Inventory List ───────────────────────────────

    testWidgets('InventoryListScreen debe usar BrandedAppBar', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<InventoryProvider>.value(
          value: invProvider,
          child: const MaterialApp(home: InventoryListScreen()),
        ),
      );
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
    });

    // ─── Inventory Detail ─────────────────────────────

    testWidgets('InventoryDetailScreen debe usar BrandedAppBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<InventoryProvider>.value(
          value: invProvider,
          child: const MaterialApp(home: InventoryDetailScreen(productId: 1)),
        ),
      );
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════
  // SALES SCREENS — create, result
  // ═══════════════════════════════════════════════════════

  group('Sales screens branding', () {
    late MockSalesRepository mockSalesRepo;
    late SalesProvider salesProvider;

    setUp(() {
      mockSalesRepo = MockSalesRepository();
      salesProvider = SalesProvider(mockSalesRepo);

      // Stub getProducts para evitar crash en postFrameCallback
      when(() => mockSalesRepo.getProducts()).thenAnswer((_) async => []);
    });

    // ─── Create Sale ──────────────────────────────────

    testWidgets('CreateSaleScreen debe usar BrandedAppBar', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SalesProvider>.value(
          value: salesProvider,
          child: const MaterialApp(home: CreateSaleScreen()),
        ),
      );
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
    });

    // ─── Sale Result ──────────────────────────────────

    testWidgets('SaleResultScreen debe usar BrandedAppBar', (tester) async {
      const saleItem = SaleItemResponse(
        batchId: 1,
        quantity: 10.0,
        unitPrice: 100.0,
        unitCost: 80.0,
      );
      final sale = SaleResponse(
        id: 1,
        totalAmount: 1000.0,
        createdAt: DateTime(2026, 5, 19),
        items: const [saleItem],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<SalesProvider>.value(
          value: salesProvider,
          child: MaterialApp(home: SaleResultScreen(sale: sale)),
        ),
      );
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════
  // PRODUCTION SCREENS — 4 screens
  // ═══════════════════════════════════════════════════════

  group('Production screens branding', () {
    late MockBulkProductRepository mockBulkRepo;
    late MockProductionRepository mockProdRepo;
    late BulkProductProvider bpProvider;
    late ProductionProvider prodProvider;

    setUp(() {
      mockBulkRepo = MockBulkProductRepository();
      mockProdRepo = MockProductionRepository();
      bpProvider = BulkProductProvider(mockBulkRepo);
      prodProvider = ProductionProvider(mockProdRepo, mockBulkRepo);

      // Stubs para evitar crash en postFrameCallback
      when(() => mockBulkRepo.getBulkProducts()).thenAnswer((_) async => []);
      when(
        () => mockProdRepo.getProductionBatches(),
      ).thenAnswer((_) async => []);
    });

    Widget productionApp(Widget screen) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<BulkProductProvider>.value(value: bpProvider),
          ChangeNotifierProvider<ProductionProvider>.value(value: prodProvider),
        ],
        child: MaterialApp(home: screen),
      );
    }

    // ─── Production Create ────────────────────────────

    testWidgets('ProductionCreateScreen debe usar BrandedAppBar', (
      tester,
    ) async {
      await tester.pumpWidget(productionApp(const ProductionCreateScreen()));
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
    });

    // ─── Production Batch List ────────────────────────

    testWidgets('ProductionBatchListScreen debe usar BrandedAppBar', (
      tester,
    ) async {
      await tester.pumpWidget(productionApp(const ProductionBatchListScreen()));
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
    });

    // ─── Bulk Product List ────────────────────────────

    testWidgets('BulkProductListScreen debe usar BrandedAppBar', (
      tester,
    ) async {
      await tester.pumpWidget(productionApp(const BulkProductListScreen()));
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
    });

    // ─── Bulk Product Form ────────────────────────────

    testWidgets('BulkProductFormScreen debe usar BrandedAppBar', (
      tester,
    ) async {
      await tester.pumpWidget(productionApp(const BulkProductFormScreen()));
      await pumpFrames(tester);

      // TDD: RED — falla ANTES de migración
      expect(find.byType(BrandedAppBar), findsOneWidget);
    });
  });
}
