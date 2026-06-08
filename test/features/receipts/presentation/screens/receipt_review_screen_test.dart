// Pruebas de widget para ReceiptReviewScreen.
//
// Cubre los 4 escenarios de R3 del spec:
// - R3.1: Muestra proveedor, fecha y líneas de productos
// - R3.2: Línea con baja confianza (<0.3) tiene indicador visual
// - R3.3: Líneas vacías muestra "No se detectaron productos"
// - R3.4: Botón Confirmar dispara flujo de confirmación
//
// También cubre el mapeo name→description de R6.1.
//
// TDD: RED — test escrito antes que la implementación completa de la pantalla

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/receipt.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_provider.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_review_screen.dart';

class MockReceiptsRepository extends Mock implements ReceiptsRepository {}

/// Crea la app de test con ReceiptsProvider real, mock repository y GoRouter.
Widget createTestApp({
  required ReceiptsProvider provider,
  required Receipt processResponse,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            ReceiptReviewScreen(processResponse: processResponse),
      ),
      GoRoute(
        path: '/receipts/confirmed',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('Confirmed'))),
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

  final processResponse = Receipt(
    id: 0,
    filename: 'https://example.com/receipt.jpg',
    detectedDate: DateTime(2026, 5, 15),
    status: 'pending',
    items: const [],
  );

  final emptyProcessResponse = Receipt(
    id: 0,
    filename: 'https://example.com/empty.jpg',
    detectedDate: null,
    status: 'pending',
    items: const [],
  );

  final purchaseResponse = Purchase(
    id: 1,
    supplierName: 'Proveedor X',
    total: 380.0,
    createdAt: DateTime(2026, 5, 15),
  );

  setUpAll(() {
    registerFallbackValue(
      const ReceiptConfirmRequest(
        imageUrl: '',
        supplierName: '',
        purchaseDate: '',
        lines: [],
      ),
    );
  });

  setUp(() {
    mockRepo = MockReceiptsRepository();
    provider = ReceiptsProvider(mockRepo);

    // Stub por defecto: procesamiento exitoso
    when(
      () => mockRepo.processReceipt(any()),
    ).thenAnswer((_) async => processResponse);

    // Stub por defecto: confirmación exitosa
    when(
      () => mockRepo.confirmReceipt(any()),
    ).thenAnswer((_) async => purchaseResponse);

    // Poner provider en imageSelected para poder procesar
    provider.selectImage('/tmp/test.jpg');
  });

  // ──────────────────────────────────────────────
  // R3.1: Muestra proveedor, fecha y líneas de productos
  // ──────────────────────────────────────────────
  group('ReceiptReviewScreen — R3.1: Datos mostrados correctamente', () {
    testWidgets('debe mostrar proveedor, fecha y líneas de productos', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(provider: provider, processResponse: processResponse),
      );
      await tester.pumpAndSettle();

      // Proveedor detectado
      expect(find.text('Proveedor X'), findsOneWidget);

      // Fecha detectada
      expect(find.text('2026-05-15'), findsOneWidget);

      // Producto 1: Leche
      expect(find.text('Leche'), findsOneWidget);

      // Producto 2: Pan
      expect(find.text('Pan'), findsOneWidget);

      // Debe mostrar el botón Confirmar
      expect(find.text('Confirmar Compra'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // R3.2: Línea con baja confianza (<0.3) tiene indicador visual
  // ──────────────────────────────────────────────
  group('ReceiptReviewScreen — R3.2: Indicador de baja confianza', () {
    testWidgets('debe mostrar indicador visual para línea con confianza <0.3', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(provider: provider, processResponse: processResponse),
      );
      await tester.pumpAndSettle();

      // Pan tiene confidence 0.15 → debe tener indicador de baja confianza
      // Buscamos un ícono de warning o texto de "baja confianza"
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // También debe mostrarse "Confianza baja" o similar
      expect(find.textContaining('baja'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // R3.3: Líneas vacías muestra mensaje
  // ──────────────────────────────────────────────
  group('ReceiptReviewScreen — R3.3: Líneas vacías', () {
    testWidgets('debe mostrar "No se detectaron productos" con líneas vacías', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          provider: provider,
          processResponse: emptyProcessResponse,
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar mensaje de que no hay productos
      expect(find.text('No se detectaron productos'), findsOneWidget);

      // El botón Confirmar no debería estar habilitado
      final confirmButton = find.widgetWithText(
        ElevatedButton,
        'Confirmar Compra',
      );
      expect(confirmButton, findsNothing);
    });
  });

  // ──────────────────────────────────────────────
  // R3.4: Botón Confirmar dispara flujo de confirmación
  // ──────────────────────────────────────────────
  group('ReceiptReviewScreen — R3.4: Confirmar flujo', () {
    testWidgets('Confirmar Compra debe llamar a confirmReceipt del provider', (
      tester,
    ) async {
      // Configurar provider en processSuccess
      provider.selectImage('/tmp/test.jpg');
      await provider.processReceipt();
      await tester.pump();

      // Usar Completer para mantener la confirmación pendiente
      final completer = Completer<Purchase>();
      when(
        () => mockRepo.confirmReceipt(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        createTestApp(provider: provider, processResponse: processResponse),
      );
      await tester.pumpAndSettle();

      // Scroll hasta que el botón Confirmar sea visible
      await tester.scrollUntilVisible(
        find.text('Confirmar Compra'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tocar Confirmar Compra
      await tester.tap(find.text('Confirmar Compra'));
      await tester.pump(); // Un frame para iniciar la operación

      // Debe mostrar CircularProgressIndicator mientras confirma
      expect(find.byType(CatLoadingIndicator), findsOneWidget);

      // Liberar el completer para que termine
      completer.complete(purchaseResponse);
      await pumpUntilSettled(tester);

      // Verificar que el repositorio fue llamado
      verify(() => mockRepo.confirmReceipt(any())).called(1);
    });

    testWidgets('Debe mapear name→description al confirmar (R6.1)', (
      tester,
    ) async {
      // Configurar provider en processSuccess
      provider.selectImage('/tmp/test.jpg');
      await provider.processReceipt();
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(provider: provider, processResponse: processResponse),
      );
      await tester.pumpAndSettle();

      // Scroll hasta que el botón Confirmar sea visible
      await tester.scrollUntilVisible(
        find.text('Confirmar Compra'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar Compra'));
      await pumpUntilSettled(tester);

      // Verificar que el request contiene description mapeado desde name
      final captured =
          verify(() => mockRepo.confirmReceipt(captureAny())).captured.single
              as ReceiptConfirmRequest;

      expect(captured.lines[0].description, 'Leche');
      expect(captured.lines[1].description, 'Pan');
    });

    testWidgets('Debe mostrar error con Reintentar si la confirmación falla', (
      tester,
    ) async {
      // Configurar fallo
      when(
        () => mockRepo.confirmReceipt(any()),
      ).thenThrow(Exception('Error del servidor'));

      provider.selectImage('/tmp/test.jpg');
      await provider.processReceipt();
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(provider: provider, processResponse: processResponse),
      );
      await tester.pumpAndSettle();

      // Scroll hasta que el botón Confirmar sea visible
      await tester.scrollUntilVisible(
        find.text('Confirmar Compra'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar Compra'));
      await pumpUntilSettled(tester);

      // Debe mostrar el error
      expect(find.textContaining('Error del servidor'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
