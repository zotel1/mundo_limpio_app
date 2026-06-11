// Pruebas de widget para el diálogo de ajuste de stock.
//
// Cubre 3 escenarios de R8:
// - R8.1: Validación del formulario (campos vacíos)
// - R8.2: Confirmación exitosa cierra el diálogo y refresca
// - R8.3: Error muestra mensaje en el diálogo
//
// TDD: RED — test escrito antes que la implementación del diálogo

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/adjustment.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/stock_item.dart';
import 'package:mundo_limpio_app/features/inventory/domain/repository/inventory_repository.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/provider/inventory_provider.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_detail_screen.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

class MockAuthProvider extends Mock implements AuthProvider {}

/// Crea la app de test con Provider para probar el dialog.
Widget createTestApp(InventoryProvider provider, {required int productId}) {
  final auth = MockAuthProvider();
  when(() => auth.roles).thenReturn(['ADMIN']);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<InventoryProvider>.value(value: provider),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: InventoryDetailScreen(productId: 1),
    ),
  );
}

/// Helper para pump repetido hasta que los async tasks resuelven.
Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockInventoryRepository mockRepo;
  late InventoryProvider provider;

  const testProductId = 1;
  const testInventory = StockItem(
    productId: testProductId,
    productName: 'Jabón Líquido',
    currentStock: 50.0,
    minStockThreshold: 10.0,
  );

  setUpAll(() {
    registerFallbackValue(
      const Adjustment(
        type: AdjustmentType.adjustment,
        quantity: 1,
        reason: 'fallback',
      ),
    );
  });

  setUp(() {
    mockRepo = MockInventoryRepository();
    provider = InventoryProvider(repository: mockRepo);

    when(
      () => mockRepo.getInventory(testProductId),
    ).thenAnswer((_) async => testInventory);
  });

  /// Helper: abre el diálogo de ajuste de stock.
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(provider, productId: testProductId));
    await pumpUntilSettled(tester);

    // Tocar "Ajustar Stock" para abrir el diálogo
    await tester.tap(find.widgetWithText(ElevatedButton, 'Ajustar Stock'));
    await tester.pumpAndSettle();
  }

  // ──────────────────────────────────────────────
  // R8.1: Validación del formulario
  // ──────────────────────────────────────────────
  group('AdjustStockDialog — R8.1: Form validation', () {
    testWidgets('debe mostrar errores de validación al enviar vacío', (
      tester,
    ) async {
      await openDialog(tester);

      // Tocar Confirmar sin llenar el formulario
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
      await tester.pumpAndSettle();

      // Debe mostrar errores de validación
      expect(find.text('Seleccioná un tipo de ajuste'), findsOneWidget);
      expect(find.text('La cantidad es requerida'), findsOneWidget);
      expect(find.text('La razón es requerida'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // R8.2: Confirmación exitosa
  // ──────────────────────────────────────────────
  group('AdjustStockDialog — R8.2: Success', () {
    testWidgets('confirmación exitosa cierra el diálogo y refresca detalle', (
      tester,
    ) async {
      // Stub adjustStock con éxito y getInventory para refresh
      when(
        () => mockRepo.adjustStock(any(), any()),
      ).thenAnswer((_) async => testInventory);

      await openDialog(tester);

      // Seleccionar tipo de ajuste
      await tester.ensureVisible(find.text('Seleccioná un tipo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seleccioná un tipo'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajuste manual').last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Ingresar cantidad
      await tester.enterText(find.byType(TextFormField).first, '10');

      // Ingresar razón
      await tester.enterText(find.byType(TextFormField).last, 'Ajuste manual');

      // Confirmar
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmar'),
        warnIfMissed: false,
      );
      await pumpUntilSettled(tester);

      // El diálogo debe cerrarse (Cancelar no debe estar visible)
      expect(find.text('Cancelar'), findsNothing);

      // El provider debe haber refrescado (inventoryLoaded)
      expect(provider.status, InventoryStatus.inventoryLoaded);
    });
  });

  // ──────────────────────────────────────────────
  // R8.3: Error en confirmación
  // ──────────────────────────────────────────────
  group('AdjustStockDialog — R8.3: Error', () {
    testWidgets('error al ajustar stock muestra mensaje en provider', (
      tester,
    ) async {
      // Stub adjustStock para que falle
      when(
        () => mockRepo.adjustStock(any(), any()),
      ).thenThrow(const UnknownApiException('Conflicto de versión', 409));

      await openDialog(tester);

      // Seleccionar tipo de ajuste
      await tester.ensureVisible(find.text('Seleccioná un tipo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seleccioná un tipo'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajuste manual').last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Ingresar cantidad
      await tester.enterText(find.byType(TextFormField).first, '10');

      // Ingresar razón
      await tester.enterText(find.byType(TextFormField).last, 'Ajuste');

      // Confirmar
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirmar'),
        warnIfMissed: false,
      );
      await pumpUntilSettled(tester);

      // El provider debe tener estado de error
      expect(provider.status, InventoryStatus.error);
      expect(provider.errorMessage, 'Conflicto de versión');
    });
  });
}
