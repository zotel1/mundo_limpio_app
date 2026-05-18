// TDD: RED — test de integración para RoleGuard con pantallas reales
//
// Verifica que RoleGuard protege pantallas de producción:
// - ADMIN puede ver BulkProductListScreen
// - OPERATOR ve Access Denied en lugar de BulkProductListScreen
// - ADMIN puede ver ProductionCreateScreen

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/helpers/role_guard.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/production_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_create_screen.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockBulkProductRepository extends Mock
    implements IBulkProductRepository {}

class MockProductionRepository extends Mock implements IProductionRepository {}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const BulkProduct(id: 0, name: '', unitOfMeasure: '', stock: 0.0),
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
        finishedProductId: 0,
        bulkProductId: 0,
        quantityUsed: 0.0,
        quantityProduced: 0.0,
        date: DateTime.now(),
      ),
    );
  });

  group('RoleGuard Integration', () {
    late MockAuthProvider mockAuth;
    late MockBulkProductRepository mockBulkRepo;
    late MockProductionRepository mockProdRepo;
    late BulkProductProvider bulkProvider;
    late ProductionProvider prodProvider;

    setUp(() {
      mockAuth = MockAuthProvider();
      mockBulkRepo = MockBulkProductRepository();
      mockProdRepo = MockProductionRepository();
      bulkProvider = BulkProductProvider(mockBulkRepo);
      prodProvider = ProductionProvider(mockProdRepo, mockBulkRepo);

      // Stubs por defecto
      when(() => mockBulkRepo.getBulkProducts()).thenAnswer(
        (_) async => [
          const BulkProduct(
            id: 1,
            name: 'Test',
            unitOfMeasure: 'L',
            stock: 10.0,
          ),
        ],
      );
      when(() => mockBulkRepo.createBulkProduct(any())).thenAnswer(
        (_) async => const BulkProduct(
          id: 1,
          name: 'Test',
          unitOfMeasure: 'L',
          stock: 10.0,
        ),
      );
      when(
        () => mockProdRepo.getProductionBatches(),
      ).thenAnswer((_) async => []);
      when(() => mockProdRepo.createProductionBatch(any())).thenAnswer(
        (_) async => ProductionBatch(
          id: 1,
          finishedProductId: 10,
          bulkProductId: 1,
          quantityUsed: 5.0,
          quantityProduced: 4.0,
          date: DateTime.now(),
        ),
      );
      when(() => mockBulkRepo.getBulkProduct(any())).thenAnswer(
        (_) async => const BulkProduct(
          id: 1,
          name: 'Alcohol',
          unitOfMeasure: 'L',
          stock: 100.0,
        ),
      );
    });

    testWidgets('BulkProductListScreen con RoleGuard — ADMIN ve el contenido', (
      tester,
    ) async {
      // Arrange
      when(() => mockAuth.role).thenReturn('ADMIN');
      await bulkProvider.getBulkProducts();
      await pumpUntilSettled(tester);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<BulkProductProvider>.value(
              value: bulkProvider,
            ),
          ],
          child: const MaterialApp(
            home: RoleGuard(
              requiredRole: 'ADMIN',
              child: BulkProductListScreen(),
            ),
          ),
        ),
      );
      await pumpUntilSettled(tester);

      // Assert: AppBar visible
      expect(find.text('Materias Primas'), findsOneWidget);
      expect(find.textContaining('Access Denied'), findsNothing);
    });

    testWidgets(
      'BulkProductListScreen con RoleGuard — OPERATOR ve Access Denied',
      (tester) async {
        // Arrange
        when(() => mockAuth.role).thenReturn('OPERATOR');
        await bulkProvider.getBulkProducts();
        await pumpUntilSettled(tester);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
              ChangeNotifierProvider<BulkProductProvider>.value(
                value: bulkProvider,
              ),
            ],
            child: const MaterialApp(
              home: RoleGuard(
                requiredRole: 'ADMIN',
                child: BulkProductListScreen(),
              ),
            ),
          ),
        );
        await pumpUntilSettled(tester);

        // Assert: Access Denied visible, not the screen
        expect(find.textContaining('Access Denied'), findsOneWidget);
        expect(find.text('Materias Primas'), findsNothing);
      },
    );

    testWidgets(
      'ProductionCreateScreen con RoleGuard — ADMIN ve el contenido',
      (tester) async {
        // Arrange
        when(() => mockAuth.role).thenReturn('ADMIN');
        // Pre-cargar materias primas para el dropdown
        await bulkProvider.getBulkProducts();
        await pumpUntilSettled(tester);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
              ChangeNotifierProvider<BulkProductProvider>.value(
                value: bulkProvider,
              ),
              ChangeNotifierProvider<ProductionProvider>.value(
                value: prodProvider,
              ),
            ],
            child: const MaterialApp(
              home: RoleGuard(
                requiredRole: 'ADMIN',
                child: ProductionCreateScreen(),
              ),
            ),
          ),
        );
        await pumpUntilSettled(tester);

        // Assert: AppBar visible
        expect(find.text('Nueva Producción'), findsOneWidget);
        expect(find.textContaining('Access Denied'), findsNothing);
      },
    );
  });
}
