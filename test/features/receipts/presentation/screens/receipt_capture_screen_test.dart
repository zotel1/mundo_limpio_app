// Pruebas de widget para ReceiptCaptureScreen.
//
// Cubre los 4 escenarios de R1 y R2 del spec:
// - R1.1/R1.2: Botones de cámara y galería visibles en idle
// - R1.1/R1.2: Selección de imagen → preview + botón procesar
// - R2.1: Estado processing → CircularProgressIndicator
// - R2.2-R2.4: Estado error → mensaje + botón reintentar
//
// Usa ReceiptsProvider real con MockReceiptsRepository para probar
// la integración completa entre UI y provider.
//
// TDD: RED — test escrito antes que la implementación completa de la pantalla

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/product_line_dto.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_provider.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_capture_screen.dart';

class MockReceiptsRepository extends Mock implements ReceiptsRepository {}

/// Crea la app de test con ReceiptsProvider real, mock repository y GoRouter.
Widget createTestApp(ReceiptsProvider provider) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, _) => const ReceiptCaptureScreen()),
      GoRoute(
        path: '/receipts/review',
        builder: (context, _) =>
            const Scaffold(body: Center(child: Text('Review'))),
      ),
    ],
  );

  return ChangeNotifierProvider<ReceiptsProvider>.value(
    value: provider,
    child: MaterialApp.router(routerConfig: router),
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

  final processResponse = ReceiptProcessResponse(
    detectedSupplier: 'Proveedor X',
    detectedDate: '2026-05-15',
    lines: const [
      ProductLineDto(
        name: 'Leche',
        quantity: 2,
        unitPrice: 150.0,
        confidence: 0.95,
        bulkProductId: 1,
      ),
    ],
    imageUrl: 'https://example.com/receipt.jpg',
  );

  setUp(() {
    mockRepo = MockReceiptsRepository();
    provider = ReceiptsProvider(mockRepo);

    // Stub por defecto: procesamiento exitoso
    when(
      () => mockRepo.processReceipt(any()),
    ).thenAnswer((_) async => processResponse);
  });

  // ──────────────────────────────────────────────
  // R1.1/R1.2: Botones de cámara y galería visibles en idle
  // ──────────────────────────────────────────────
  group('ReceiptCaptureScreen — Estado idle', () {
    testWidgets('debe mostrar botones de cámara y galería en estado idle', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(provider));
      await tester.pumpAndSettle();

      // Debe mostrar el botón de cámara
      expect(find.text('Cámara'), findsOneWidget);

      // Debe mostrar el botón de galería
      expect(find.text('Galería'), findsOneWidget);

      // No debe mostrar vista previa de imagen
      expect(find.byType(Image), findsNothing);

      // No debe mostrar botón de procesar
      expect(find.text('Procesar Recibo'), findsNothing);
    });
  });

  // ──────────────────────────────────────────────
  // R1.1/R1.2: Selección de imagen → preview + botón procesar
  // ──────────────────────────────────────────────
  group('ReceiptCaptureScreen — Estado imageSelected', () {
    testWidgets(
      'debe mostrar preview de imagen y botón procesar tras selección',
      (tester) async {
        await tester.pumpWidget(createTestApp(provider));
        await tester.pumpAndSettle();

        // Simular selección de imagen (como lo haría el image_picker)
        provider.selectImage('/tmp/test_receipt.jpg');
        await tester.pumpAndSettle();

        // Debe mostrar el texto del path (simulando preview)
        // La pantalla debe reflejar el estado imageSelected
        expect(provider.status, ReceiptsStatus.imageSelected);

        // Debe mostrar el botón "Procesar Recibo"
        expect(find.text('Procesar Recibo'), findsOneWidget);

        // Los botones de cámara/galería pueden desaparecer o permanecer
        // según diseño — verificamos que al menos el botón procesar está presente
      },
    );
  });

  // ──────────────────────────────────────────────
  // R2.1: Estado processing → CircularProgressIndicator
  // ──────────────────────────────────────────────
  group('ReceiptCaptureScreen — Estado processing', () {
    testWidgets(
      'debe mostrar CircularProgressIndicator durante procesamiento',
      (tester) async {
        // Arrange: mantener el procesamiento pendiente con un Completer
        final completer = Completer<ReceiptProcessResponse>();
        when(
          () => mockRepo.processReceipt(any()),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestApp(provider));
        await tester.pumpAndSettle();

        // Seleccionar imagen
        provider.selectImage('/tmp/test_receipt.jpg');
        await tester.pumpAndSettle();

        // Iniciar procesamiento
        unawaited(provider.processReceipt());
        await tester.pump();

        // Debe mostrar CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Cleanup: liberar el completer
        completer.complete(processResponse);
      },
    );
  });

  // ──────────────────────────────────────────────
  // R2.2-R2.4: Estado error → mensaje + botón reintentar
  // ──────────────────────────────────────────────
  group('ReceiptCaptureScreen — Estado error', () {
    testWidgets('debe mostrar mensaje de error y botón Reintentar en error', (
      tester,
    ) async {
      // Arrange: provider en estado error con mensaje
      await tester.pumpWidget(createTestApp(provider));
      await tester.pumpAndSettle();

      // Forzar estado de error manualmente vía selectImage + process con error
      provider.selectImage('/tmp/test_receipt.jpg');
      await tester.pumpAndSettle();

      when(
        () => mockRepo.processReceipt(any()),
      ).thenThrow(Exception('Error de conexión'));

      await provider.processReceipt();
      await tester.pumpAndSettle();

      expect(provider.status, ReceiptsStatus.error);

      // Debe mostrar el mensaje de error
      expect(find.textContaining('Error de conexión'), findsOneWidget);

      // Debe mostrar botón "Reintentar"
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar debe volver a procesar la imagen', (tester) async {
      // Arrange: error primero
      await tester.pumpWidget(createTestApp(provider));
      await tester.pumpAndSettle();

      provider.selectImage('/tmp/test_receipt.jpg');
      await tester.pumpAndSettle();

      when(
        () => mockRepo.processReceipt(any()),
      ).thenThrow(Exception('Error temporal'));

      await provider.processReceipt();
      await tester.pumpAndSettle();

      expect(provider.status, ReceiptsStatus.error);

      // Arrange: éxito al reintentar
      when(
        () => mockRepo.processReceipt(any()),
      ).thenAnswer((_) async => processResponse);

      // Act: tocar Reintentar
      await tester.tap(find.text('Reintentar'));
      await pumpUntilSettled(tester);

      // Assert: debe estar en processSuccess
      expect(provider.status, ReceiptsStatus.processSuccess);
    });
  });
}
