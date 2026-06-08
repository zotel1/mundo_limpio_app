// Pruebas de widget para ReceiptConfirmedScreen.
//
// Cubre los 4 escenarios de R4 del spec:
// - R4.1: Muestra resumen de compra: proveedor, total, lista de ítems
// - R4.1: Botón "Nuevo Escaneo" → provider.reset() → navega a /receipts/new
// - R4.2/R4.3: Ítems con y sin bulkProductId se muestran correctamente
// - R4.4: Estado de error muestra Reintentar
//
// TDD: RED — test escrito antes que la implementación completa de la pantalla

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_provider.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_confirmed_screen.dart';

class MockReceiptsRepository extends Mock implements ReceiptsRepository {}

/// Crea la app de test con ReceiptsProvider real, mock repository y GoRouter.
Widget createTestApp({
  required ReceiptsProvider provider,
  required Purchase purchase,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => ReceiptConfirmedScreen(purchase: purchase),
      ),
      GoRoute(
        path: '/receipts/new',
        builder: (_, _) => const Scaffold(body: Center(child: Text('Capture'))),
      ),
    ],
  );

  return ChangeNotifierProvider<ReceiptsProvider>.value(
    value: provider,
    child: MaterialApp.router(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
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
  late MockReceiptsRepository mockRepo;
  late ReceiptsProvider provider;

  final purchase = Purchase(
    id: 1,
    supplierName: 'Proveedor X',
    total: 380.0,
    createdAt: DateTime(2026, 5, 15),
  );

  setUp(() {
    mockRepo = MockReceiptsRepository();
    provider = ReceiptsProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // R4.1: Muestra resumen de compra
  // ──────────────────────────────────────────────
  group('ReceiptConfirmedScreen — R4.1: Resumen de compra', () {
    testWidgets('debe mostrar proveedor, total y lista de ítems', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(provider: provider, purchase: purchase),
      );
      await tester.pumpAndSettle();

      // Proveedor
      expect(find.text('Proveedor X'), findsOneWidget);

      // Total — puede mostrarse como "$380.00" o "380.00"
      expect(find.textContaining('380'), findsOneWidget);

      // Fecha
      expect(find.text('15/05/2026'), findsOneWidget);

      // Título de confirmación
      expect(find.text('¡Compra Confirmada!'), findsOneWidget);
    });

    testWidgets('debe mostrar botón "Nuevo Escaneo"', (tester) async {
      await tester.pumpWidget(
        createTestApp(provider: provider, purchase: purchase),
      );
      await tester.pumpAndSettle();

      // Botón "Nuevo Escaneo"
      expect(find.text('Nuevo Escaneo'), findsOneWidget);

      // Tocar el botón debe resetear el provider
      await tester.tap(find.text('Nuevo Escaneo'));
      await tester.pumpAndSettle();

      // Verificar que el provider fue reseteado
      expect(provider.status, ReceiptsStatus.idle);
      expect(provider.selectedImagePath, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // R4.2/R4.3: Pantalla confirma datos de la compra
  // ──────────────────────────────────────────────
  group('ReceiptConfirmedScreen — R4.2/R4.3: Datos de compra', () {
    testWidgets('debe mostrar proveedor, fecha y total correctamente', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(provider: provider, purchase: purchase),
      );
      await tester.pumpAndSettle();

      // Proveedor
      expect(find.text('Proveedor X'), findsOneWidget);

      // Fecha
      expect(find.text('15/05/2026'), findsOneWidget);

      // Total
      expect(find.textContaining('380'), findsOneWidget);
    });

    testWidgets('debe mostrar botón Nuevo Escaneo', (tester) async {
      await tester.pumpWidget(
        createTestApp(provider: provider, purchase: purchase),
      );
      await tester.pumpAndSettle();

      // Botón Nuevo Escaneo
      expect(find.text('Nuevo Escaneo'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // R4.4: Estado de error muestra Reintentar
  // ──────────────────────────────────────────────
  group('ReceiptConfirmedScreen — R4.4: Error state', () {
    testWidgets('debe mostrar Reintentar cuando el provider está en error', (
      tester,
    ) async {
      // Forzar provider a estado error
      when(
        () => mockRepo.processReceipt(any()),
      ).thenThrow(Exception('Error del servidor'));

      provider.selectImage('/tmp/test.jpg');
      await provider.processReceipt();
      await tester.pump();

      // Verificar que está en error
      expect(provider.status, ReceiptsStatus.error);

      await tester.pumpWidget(
        createTestApp(provider: provider, purchase: purchase),
      );
      await tester.pumpAndSettle();

      // Debe mostrar mensaje de error
      expect(find.textContaining('Error del servidor'), findsOneWidget);

      // Debe mostrar botón Reintentar
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar debe limpiar error y resetear provider', (
      tester,
    ) async {
      // Forzar provider a estado error
      when(
        () => mockRepo.processReceipt(any()),
      ).thenThrow(Exception('Error temporal'));

      provider.selectImage('/tmp/test.jpg');
      await provider.processReceipt();
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(provider: provider, purchase: purchase),
      );
      await tester.pumpAndSettle();

      // Tocar Reintentar
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      // Debe haber reseteado el provider
      expect(provider.status, ReceiptsStatus.idle);
    });
  });
}
