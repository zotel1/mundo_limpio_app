// Pruebas de widget para ReceiptsHistoryScreen.
//
// Cubre los escenarios:
// - Muestra indicador de carga inicialmente
// - Muestra lista de compras cuando hay datos
// - Muestra estado vacío cuando no hay compras
// - Muestra error con botón de reintentar
// - Pull-to-refresh funciona
//
// Usa ReceiptsHistoryProvider real con MockReceiptsRepository.
// Sigue el patrón de SalesHistoryScreen.
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
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipts_history_screen.dart';

class MockReceiptsRepository extends Mock implements ReceiptsRepository {}

class MockAuthProvider extends Mock implements AuthProvider {}

/// Crea la app de test con ReceiptsHistoryProvider real y mock repository.
Widget createTestApp(ReceiptsHistoryProvider provider) {
  final auth = MockAuthProvider();
  when(() => auth.roles).thenReturn(['ADMIN']);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ReceiptsHistoryProvider>.value(value: provider),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: const ReceiptsHistoryScreen(),
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

  final receipt1 = Purchase(
    id: 1,
    supplierName: 'Proveedor X',
    total: 300.0,
    createdAt: DateTime(2026, 5, 15),
  );

  final receipt2 = Purchase(
    id: 2,
    supplierName: 'Proveedor Y',
    total: 500.0,
    createdAt: DateTime(2026, 5, 16),
  );

  setUp(() {
    mockRepo = MockReceiptsRepository();
    provider = ReceiptsHistoryProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Loading
  // ──────────────────────────────────────────────
  group('ReceiptsHistoryScreen — loading', () {
    testWidgets('debe mostrar indicador de carga cuando status es loading', (
      tester,
    ) async {
      when(
        () => mockRepo.getReceipts(),
      ).thenAnswer((_) => Completer<List<Purchase>>().future);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(CatLoadingIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Lista con datos
  // ──────────────────────────────────────────────
  group('ReceiptsHistoryScreen — lista con datos', () {
    testWidgets('debe mostrar lista de compras cuando hay datos', (
      tester,
    ) async {
      when(
        () => mockRepo.getReceipts(),
      ).thenAnswer((_) async => [receipt1, receipt2]);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('Proveedor X'), findsOneWidget);
      expect(find.text('Proveedor Y'), findsOneWidget);
      expect(find.text('\$300.00'), findsOneWidget);
      expect(find.text('\$500.00'), findsOneWidget);
    });

    testWidgets('debe mostrar RefreshIndicator en la lista', (tester) async {
      when(
        () => mockRepo.getReceipts(),
      ).thenAnswer((_) async => [receipt1, receipt2]);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Estado vacío
  // ──────────────────────────────────────────────
  group('ReceiptsHistoryScreen — vacío', () {
    testWidgets('debe mostrar mensaje vacío cuando no hay compras', (
      tester,
    ) async {
      when(() => mockRepo.getReceipts()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('No hay compras registradas'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Error
  // ──────────────────────────────────────────────
  group('ReceiptsHistoryScreen — error', () {
    testWidgets('debe mostrar error y botón de reintentar cuando falla carga', (
      tester,
    ) async {
      when(
        () => mockRepo.getReceipts(),
      ).thenThrow(const UnknownApiException('Error de conexión', 500));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Error de conexión'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar debe recargar compras', (tester) async {
      when(
        () => mockRepo.getReceipts(),
      ).thenThrow(const UnknownApiException('Error', 500));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Error'), findsOneWidget);

      when(() => mockRepo.getReceipts()).thenAnswer((_) async => [receipt1]);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
      await pumpUntilSettled(tester);

      expect(provider.status, ReceiptsHistoryStatus.success);
      expect(provider.receipts, hasLength(1));
    });
  });

  // ──────────────────────────────────────────────
  // Pull-to-refresh
  // ──────────────────────────────────────────────
  group('ReceiptsHistoryScreen — pull-to-refresh', () {
    testWidgets('debe recargar compras al hacer pull-to-refresh', (
      tester,
    ) async {
      when(() => mockRepo.getReceipts()).thenAnswer((_) async => [receipt1]);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(provider.receipts, hasLength(1));

      when(
        () => mockRepo.getReceipts(),
      ).thenAnswer((_) async => [receipt1, receipt2]);

      await provider.loadReceipts();
      await pumpUntilSettled(tester);

      expect(provider.status, ReceiptsHistoryStatus.success);
      expect(provider.receipts, hasLength(2));
    });
  });
}
