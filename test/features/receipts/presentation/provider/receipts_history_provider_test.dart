// Pruebas unitarias para ReceiptsHistoryProvider.
//
// Verifica la máquina de estados del historial de recibos:
//   idle → loadReceipts() → loading → success | error
//   idle → loadReceiptById(id) → loading → success | error
//   error → clearError() → idle
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_history_provider.dart';

class MockReceiptsRepository extends Mock implements ReceiptsRepository {}

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
  // Estado inicial
  // ──────────────────────────────────────────────
  group('estado inicial', () {
    test(
      'status debe ser idle, receipts vacío, selectedReceipt y error null',
      () {
        expect(provider.status, ReceiptsHistoryStatus.idle);
        expect(provider.receipts, isEmpty);
        expect(provider.selectedReceipt, isNull);
        expect(provider.errorMessage, isNull);
      },
    );
  });

  // ──────────────────────────────────────────────
  // loadReceipts
  // ──────────────────────────────────────────────
  group('loadReceipts', () {
    test(
      'debe transitar idle → loading → success y exponer lista de recibos',
      () async {
        when(
          () => mockRepo.getReceipts(),
        ).thenAnswer((_) async => [receipt1, receipt2]);

        await provider.loadReceipts();

        expect(provider.status, ReceiptsHistoryStatus.success);
        expect(provider.receipts, hasLength(2));
        expect(provider.receipts[0].id, 1);
        expect(provider.receipts[1].id, 2);
      },
    );

    test(
      'debe fallar con error cuando getReceipts lanza ApiException',
      () async {
        when(
          () => mockRepo.getReceipts(),
        ).thenThrow(const ApiException('Error al cargar recibos', 500));

        await provider.loadReceipts();

        expect(provider.status, ReceiptsHistoryStatus.error);
        expect(provider.errorMessage, contains('Error al cargar recibos'));
      },
    );

    test('debe limpiar errorMessage antes de recargar', () async {
      when(
        () => mockRepo.getReceipts(),
      ).thenThrow(const ApiException('Error previo', 500));
      await provider.loadReceipts();
      expect(provider.errorMessage, isNotNull);

      when(() => mockRepo.getReceipts()).thenAnswer((_) async => [receipt1]);

      await provider.loadReceipts();

      expect(provider.status, ReceiptsHistoryStatus.success);
      expect(provider.errorMessage, isNull);
    });

    test('debe retornar lista vacía cuando no hay recibos', () async {
      when(() => mockRepo.getReceipts()).thenAnswer((_) async => []);

      await provider.loadReceipts();

      expect(provider.status, ReceiptsHistoryStatus.success);
      expect(provider.receipts, isEmpty);
    });

    test('debe manejar errores genéricos (no ApiException)', () async {
      when(() => mockRepo.getReceipts()).thenThrow(Exception('Algo salió mal'));

      await provider.loadReceipts();

      expect(provider.status, ReceiptsHistoryStatus.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // ──────────────────────────────────────────────
  // loadReceiptById
  // ──────────────────────────────────────────────
  group('loadReceiptById', () {
    test(
      'debe transitar idle → loading → success y exponer el recibo',
      () async {
        when(
          () => mockRepo.getReceiptById(1),
        ).thenAnswer((_) async => receipt1);

        await provider.loadReceiptById(1);

        expect(provider.status, ReceiptsHistoryStatus.success);
        expect(provider.selectedReceipt, isNotNull);
        expect(provider.selectedReceipt!.id, 1);
        expect(provider.selectedReceipt!.supplierName, 'Proveedor X');
      },
    );

    test(
      'debe fallar con error cuando getReceiptById lanza ApiException',
      () async {
        when(
          () => mockRepo.getReceiptById(99),
        ).thenThrow(const ApiException('Recibo no encontrado', 404));

        await provider.loadReceiptById(99);

        expect(provider.status, ReceiptsHistoryStatus.error);
        expect(provider.errorMessage, contains('Recibo no encontrado'));
      },
    );

    test('debe manejar errores genéricos en loadReceiptById', () async {
      when(
        () => mockRepo.getReceiptById(1),
      ).thenThrow(Exception('Error inesperado'));

      await provider.loadReceiptById(1);

      expect(provider.status, ReceiptsHistoryStatus.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // ──────────────────────────────────────────────
  // clearError
  // ──────────────────────────────────────────────
  group('clearError', () {
    test('debe volver a idle con errorMessage null', () async {
      when(
        () => mockRepo.getReceipts(),
      ).thenThrow(const ApiException('Error', 500));
      await provider.loadReceipts();
      expect(provider.status, ReceiptsHistoryStatus.error);

      provider.clearError();

      expect(provider.status, ReceiptsHistoryStatus.idle);
      expect(provider.errorMessage, isNull);
    });

    test('no debe fallar si no hay error previo', () {
      provider.clearError();

      expect(provider.status, ReceiptsHistoryStatus.idle);
      expect(provider.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // Múltiples llamadas
  // ──────────────────────────────────────────────
  group('múltiples llamadas', () {
    test(
      'debe recargar recibos correctamente (loadReceipts dos veces)',
      () async {
        when(() => mockRepo.getReceipts()).thenAnswer((_) async => [receipt1]);
        await provider.loadReceipts();
        expect(provider.receipts, hasLength(1));

        when(
          () => mockRepo.getReceipts(),
        ).thenAnswer((_) async => [receipt1, receipt2]);

        await provider.loadReceipts();

        expect(provider.status, ReceiptsHistoryStatus.success);
        expect(provider.receipts, hasLength(2));
      },
    );

    test(
      'debe ejecutar loadReceipts y luego loadReceiptById secuencialmente',
      () async {
        when(
          () => mockRepo.getReceipts(),
        ).thenAnswer((_) async => [receipt1, receipt2]);
        when(
          () => mockRepo.getReceiptById(1),
        ).thenAnswer((_) async => receipt1);

        await provider.loadReceipts();
        expect(provider.status, ReceiptsHistoryStatus.success);
        expect(provider.receipts, hasLength(2));

        await provider.loadReceiptById(1);

        expect(provider.status, ReceiptsHistoryStatus.success);
        expect(provider.selectedReceipt, isNotNull);
        expect(provider.selectedReceipt!.id, 1);
      },
    );
  });

  // ──────────────────────────────────────────────
  // ChangeNotifier
  // ──────────────────────────────────────────────
  group('ChangeNotifier', () {
    test('debe extender ChangeNotifier', () {
      expect(provider, isA<ChangeNotifier>());
    });

    test('debe llamar notifyListeners durante loadReceipts', () async {
      when(() => mockRepo.getReceipts()).thenAnswer((_) async => [receipt1]);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadReceipts();

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante loadReceiptById', () async {
      when(() => mockRepo.getReceiptById(1)).thenAnswer((_) async => receipt1);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadReceiptById(1);

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners en clearError', () async {
      when(
        () => mockRepo.getReceipts(),
      ).thenThrow(const ApiException('Error', 500));
      await provider.loadReceipts();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();

      expect(notifyCount, greaterThan(0));
    });
  });
}
