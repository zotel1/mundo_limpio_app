// Pruebas de widget para ReceiptDetailScreen.
//
// Cubre los escenarios:
// - Muestra indicador de carga inicialmente
// - Muestra detalle cuando hay datos (header, items)
// - Muestra error con botón de reintentar
//
// Usa ReceiptsHistoryProvider real con MockReceiptsRepository.
// Sigue el patrón de SaleDetailScreen.
//
// TDD: RED — test escrito antes que la implementación de la pantalla

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_history_provider.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_detail_screen.dart';

class MockReceiptsRepository extends Mock implements ReceiptsRepository {}

class MockAuthProvider extends Mock implements AuthProvider {}

/// Crea la app de test con ReceiptsHistoryProvider real y mock repository.
Widget createTestApp(ReceiptsHistoryProvider provider, int receiptId) {
  final auth = MockAuthProvider();
  when(() => auth.roles).thenReturn(['ADMIN']);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ReceiptsHistoryProvider>.value(value: provider),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: ReceiptDetailScreen(receiptId: receiptId),
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
  late ReceiptsHistoryProvider provider;

  final receipt = Purchase(
    id: 42,
    supplierName: 'Proveedor de Prueba',
    total: 300.0,
    createdAt: DateTime(2026, 5, 15, 10, 30, 0),
  );

  setUp(() {
    mockRepo = MockReceiptsRepository();
    provider = ReceiptsHistoryProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Loading
  // ──────────────────────────────────────────────
  group('ReceiptDetailScreen — loading', () {
    testWidgets('debe mostrar indicador de carga cuando status es loading', (
      tester,
    ) async {
      when(
        () => mockRepo.getReceiptById(any()),
      ).thenAnswer((_) => Completer<Purchase>().future);

      await tester.pumpWidget(createTestApp(provider, 42));
      await pumpUntilSettled(tester);

      expect(find.byType(CatLoadingIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Detalle
  // ──────────────────────────────────────────────
  group('ReceiptDetailScreen — detalle', () {
    testWidgets('debe mostrar detalle de compra cuando se carga exitosamente', (
      tester,
    ) async {
      when(() => mockRepo.getReceiptById(42)).thenAnswer((_) async => receipt);

      await tester.pumpWidget(createTestApp(provider, 42));
      await pumpUntilSettled(tester);

      // Header
      expect(find.text('Proveedor de Prueba'), findsOneWidget);
      expect(find.textContaining('\$300.00'), findsAtLeast(1));

      // Items
      expect(find.text('Leche'), findsOneWidget);
      expect(find.textContaining('2'), findsAtLeast(1));
      expect(find.textContaining('\$150.00'), findsAtLeast(1));
    });

    testWidgets('debe mostrar mensaje cuando no hay compra seleccionada', (
      tester,
    ) async {
      when(() => mockRepo.getReceiptById(99)).thenAnswer((_) async => receipt);
      provider = ReceiptsHistoryProvider(mockRepo);

      await tester.pumpWidget(createTestApp(provider, 99));
      await pumpUntilSettled(tester);

      // No crashea
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Error
  // ──────────────────────────────────────────────
  group('ReceiptDetailScreen — error', () {
    testWidgets('debe mostrar error y botón de reintentar cuando falla carga', (
      tester,
    ) async {
      when(
        () => mockRepo.getReceiptById(42),
      ).thenThrow(const ApiException('Compra no encontrada', 404));

      await tester.pumpWidget(createTestApp(provider, 42));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Compra no encontrada'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar debe recargar detalle de compra', (tester) async {
      when(
        () => mockRepo.getReceiptById(42),
      ).thenThrow(const ApiException('Error', 500));

      await tester.pumpWidget(createTestApp(provider, 42));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Error'), findsOneWidget);

      when(() => mockRepo.getReceiptById(42)).thenAnswer((_) async => receipt);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
      await pumpUntilSettled(tester);

      expect(provider.status, ReceiptsHistoryStatus.success);
      expect(provider.selectedReceipt, isNotNull);
      expect(provider.selectedReceipt!.id, 42);
    });
  });
}
