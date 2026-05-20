// Pruebas unitarias para ReceiptsProvider.
//
// Verifica la máquina de estados del flujo de escaneo OCR:
//   idle ──selectImage()──→ imageSelected ──processReceipt()──→ processing → processSuccess
//   processSuccess ──confirmReceipt()──→ confirming → confirmed
//   Cualquier error ──→ error ──clearError()──→ idle
//   error ──selectImage()──→ imageSelected (recovery)
//
// TDD: RED — test escrito antes que la implementación del provider

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/product_line_dto.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/product_line_confirm_dto.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_item_response.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_provider.dart';

class MockReceiptsRepository extends Mock implements ReceiptsRepository {}

void main() {
  late MockReceiptsRepository mockRepo;
  late ReceiptsProvider provider;

  // ── Mock data factories ──

  const testImagePath = '/tmp/test_receipt.jpg';

  final processSuccessResponse = ReceiptProcessResponse(
    detectedSupplier: 'Proveedor X',
    detectedDate: '2026-05-15',
    lines: const [
      ProductLineDto(
        name: 'Leche Entera',
        quantity: 2,
        unitPrice: 150.0,
        confidence: 0.95,
        bulkProductId: 1,
      ),
    ],
    imageUrl: 'https://storage.example.com/receipts/img1.jpg',
  );

  final confirmRequest = ReceiptConfirmRequest(
    imageUrl: 'https://storage.example.com/receipts/img1.jpg',
    supplierName: 'Proveedor X',
    purchaseDate: '2026-05-15',
    lines: const [
      ProductLineConfirmDto(
        description: 'Leche Entera',
        quantity: 2,
        unitPrice: 150.0,
        bulkProductId: 1,
      ),
    ],
  );

  final purchaseSuccessResponse = PurchaseResponse(
    id: 42,
    imageUrl: 'https://storage.example.com/receipts/img1.jpg',
    supplierName: 'Proveedor X',
    purchaseDate: DateTime(2026, 5, 15),
    total: 300.0,
    items: const [
      PurchaseItemResponse(
        id: 1,
        description: 'Leche Entera',
        quantity: 2,
        unitPrice: 150.0,
        totalPrice: 300.0,
        bulkProductId: 1,
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(confirmRequest);
  });

  setUp(() {
    mockRepo = MockReceiptsRepository();
    provider = ReceiptsProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Estado inicial
  // ──────────────────────────────────────────────
  group('estado inicial', () {
    test('status debe ser idle', () {
      expect(provider.status, ReceiptsStatus.idle);
    });

    test('processResponse debe ser null', () {
      expect(provider.processResponse, isNull);
    });

    test('purchaseResponse debe ser null', () {
      expect(provider.purchaseResponse, isNull);
    });

    test('selectedImagePath debe ser null', () {
      expect(provider.selectedImagePath, isNull);
    });

    test('errorMessage debe ser null', () {
      expect(provider.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // selectImage
  // ──────────────────────────────────────────────
  group('selectImage', () {
    test('debe transitar idle → imageSelected y almacenar path', () {
      // Act
      provider.selectImage(testImagePath);

      // Assert
      expect(provider.status, ReceiptsStatus.imageSelected);
      expect(provider.selectedImagePath, testImagePath);
    });

    test('debe limpiar errorMessage al seleccionar nueva imagen', () async {
      // Arrange: forzar error primero
      when(
        () => mockRepo.processReceipt(any()),
      ).thenThrow(const ApiException('Error de red', 0));
      provider.selectImage('/tmp/bad.jpg');
      await provider.processReceipt();
      expect(provider.status, ReceiptsStatus.error);
      expect(provider.errorMessage, isNotNull);

      // Act: seleccionar nueva imagen desde error (recovery)
      provider.selectImage(testImagePath);

      // Assert
      expect(provider.status, ReceiptsStatus.imageSelected);
      expect(provider.selectedImagePath, testImagePath);
      expect(provider.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // resetImage
  // ──────────────────────────────────────────────
  group('resetImage', () {
    test('debe transitar imageSelected → idle y limpiar path', () {
      // Arrange
      provider.selectImage(testImagePath);

      // Act
      provider.resetImage();

      // Assert
      expect(provider.status, ReceiptsStatus.idle);
      expect(provider.selectedImagePath, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // processReceipt
  // ──────────────────────────────────────────────
  group('processReceipt', () {
    test(
      'debe transitar imageSelected → processing → processSuccess y setear processResponse',
      () async {
        // Arrange
        provider.selectImage(testImagePath);
        when(
          () => mockRepo.processReceipt(testImagePath),
        ).thenAnswer((_) async => processSuccessResponse);

        // Act
        await provider.processReceipt();

        // Assert
        expect(provider.status, ReceiptsStatus.processSuccess);
        expect(provider.processResponse, isNotNull);
        expect(provider.processResponse!.detectedSupplier, 'Proveedor X');
        expect(provider.processResponse!.lines, hasLength(1));
        expect(provider.processResponse!.lines[0].name, 'Leche Entera');
      },
    );

    test(
      'debe setear error y errorMessage cuando processReceipt lanza ApiException',
      () async {
        // Arrange
        provider.selectImage(testImagePath);
        when(
          () => mockRepo.processReceipt(testImagePath),
        ).thenThrow(const ApiException('Error de procesamiento OCR', 422));

        // Act
        await provider.processReceipt();

        // Assert
        expect(provider.status, ReceiptsStatus.error);
        expect(provider.errorMessage, contains('Error de procesamiento OCR'));
      },
    );

    test(
      'debe setear error y errorMessage con error genérico (no ApiException)',
      () async {
        // Arrange
        provider.selectImage(testImagePath);
        when(
          () => mockRepo.processReceipt(testImagePath),
        ).thenThrow(Exception('Error inesperado de archivo'));

        // Act
        await provider.processReceipt();

        // Assert
        expect(provider.status, ReceiptsStatus.error);
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('Error inesperado'));
      },
    );

    test(
      'no debe hacer nada si no hay imagen seleccionada (precondición idle)',
      () async {
        // Arrange: estado idle, sin imagen

        // Act
        await provider.processReceipt();

        // Assert: estado no cambia
        expect(provider.status, ReceiptsStatus.idle);
        expect(provider.processResponse, isNull);
        verifyNever(() => mockRepo.processReceipt(any()));
      },
    );
  });

  // ──────────────────────────────────────────────
  // confirmReceipt
  // ──────────────────────────────────────────────
  group('confirmReceipt', () {
    /// Helper: pone el provider en processSuccess
    Future<void> setupProcessSuccess() async {
      provider.selectImage(testImagePath);
      when(
        () => mockRepo.processReceipt(testImagePath),
      ).thenAnswer((_) async => processSuccessResponse);
      await provider.processReceipt();
    }

    test(
      'debe transitar processSuccess → confirming → confirmed y setear purchaseResponse',
      () async {
        // Arrange
        await setupProcessSuccess();
        when(
          () => mockRepo.confirmReceipt(any()),
        ).thenAnswer((_) async => purchaseSuccessResponse);

        // Act
        await provider.confirmReceipt(confirmRequest);

        // Assert
        expect(provider.status, ReceiptsStatus.confirmed);
        expect(provider.purchaseResponse, isNotNull);
        expect(provider.purchaseResponse!.id, 42);
        expect(provider.purchaseResponse!.supplierName, 'Proveedor X');
        expect(provider.purchaseResponse!.total, 300.0);
        expect(provider.purchaseResponse!.items, hasLength(1));
      },
    );

    test(
      'debe setear error y errorMessage cuando confirmReceipt lanza ApiException',
      () async {
        // Arrange
        await setupProcessSuccess();
        when(
          () => mockRepo.confirmReceipt(any()),
        ).thenThrow(const ApiException('Datos de compra inválidos', 400));

        // Act
        await provider.confirmReceipt(confirmRequest);

        // Assert
        expect(provider.status, ReceiptsStatus.error);
        expect(provider.errorMessage, contains('Datos de compra inválidos'));
      },
    );

    test('debe setear error con error genérico en confirmReceipt', () async {
      // Arrange
      await setupProcessSuccess();
      when(
        () => mockRepo.confirmReceipt(any()),
      ).thenThrow(Exception('Timeout de conexión'));

      // Act
      await provider.confirmReceipt(confirmRequest);

      // Assert
      expect(provider.status, ReceiptsStatus.error);
      expect(provider.errorMessage, contains('Timeout'));
    });

    test(
      'no debe hacer nada si status no es processSuccess (precondición idle)',
      () async {
        // Arrange: estado idle

        // Act
        await provider.confirmReceipt(confirmRequest);

        // Assert: estado no cambia
        expect(provider.status, ReceiptsStatus.idle);
        expect(provider.purchaseResponse, isNull);
        verifyNever(() => mockRepo.confirmReceipt(any()));
      },
    );
  });

  // ──────────────────────────────────────────────
  // reset
  // ──────────────────────────────────────────────
  group('reset', () {
    test(
      'debe volver a idle con todos los campos limpios desde confirmed',
      () async {
        // Arrange: flujo completo exitoso
        provider.selectImage(testImagePath);
        when(
          () => mockRepo.processReceipt(testImagePath),
        ).thenAnswer((_) async => processSuccessResponse);
        await provider.processReceipt();

        when(
          () => mockRepo.confirmReceipt(any()),
        ).thenAnswer((_) async => purchaseSuccessResponse);
        await provider.confirmReceipt(confirmRequest);
        expect(provider.status, ReceiptsStatus.confirmed);

        // Act
        provider.reset();

        // Assert
        expect(provider.status, ReceiptsStatus.idle);
        expect(provider.processResponse, isNull);
        expect(provider.purchaseResponse, isNull);
        expect(provider.selectedImagePath, isNull);
        expect(provider.errorMessage, isNull);
      },
    );
  });

  // ──────────────────────────────────────────────
  // clearError
  // ──────────────────────────────────────────────
  group('clearError', () {
    test('debe setear status idle y null errorMessage', () async {
      // Arrange: forzar error
      provider.selectImage(testImagePath);
      when(
        () => mockRepo.processReceipt(testImagePath),
      ).thenThrow(const ApiException('Error', 500));
      await provider.processReceipt();
      expect(provider.status, ReceiptsStatus.error);

      // Act
      provider.clearError();

      // Assert
      expect(provider.status, ReceiptsStatus.idle);
      expect(provider.errorMessage, isNull);
    });

    test('no debe fallar si no hay error previo', () {
      // Act (sin error previo)
      provider.clearError();

      // Assert
      expect(provider.status, ReceiptsStatus.idle);
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

    test('debe llamar notifyListeners durante selectImage', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.selectImage(testImagePath);

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante resetImage', () {
      provider.selectImage(testImagePath);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.resetImage();

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante processReceipt', () async {
      provider.selectImage(testImagePath);
      when(
        () => mockRepo.processReceipt(testImagePath),
      ).thenAnswer((_) async => processSuccessResponse);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.processReceipt();

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante confirmReceipt', () async {
      provider.selectImage(testImagePath);
      when(
        () => mockRepo.processReceipt(testImagePath),
      ).thenAnswer((_) async => processSuccessResponse);
      await provider.processReceipt();

      when(
        () => mockRepo.confirmReceipt(any()),
      ).thenAnswer((_) async => purchaseSuccessResponse);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.confirmReceipt(confirmRequest);

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners en reset', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.reset();

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners en clearError', () async {
      provider.selectImage(testImagePath);
      when(
        () => mockRepo.processReceipt(testImagePath),
      ).thenThrow(const ApiException('Error', 500));
      await provider.processReceipt();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();

      expect(notifyCount, greaterThan(0));
    });
  });
}
