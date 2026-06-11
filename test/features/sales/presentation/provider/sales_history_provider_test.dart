// Pruebas unitarias para SalesHistoryProvider.
//
// Verifica la máquina de estados del historial de ventas:
//   idle → loadSales() → loading → success | error
//   idle → loadSaleById(id) → loading → success | error
//   error → clearError() → idle
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/sale.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/sale_item.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_history_provider.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

void main() {
  late MockSalesRepository mockRepo;
  late SalesHistoryProvider provider;

  const saleItem = SaleItem(
    productId: 10,
    productName: 'Producto A',
    quantity: 5.0,
    unitPrice: 100.0,
  );

  final sale1 = Sale(
    id: 1,
    total: 500.0,
    createdAt: DateTime(2026, 5, 10),
    items: const [saleItem],
    status: 'completed',
  );

  final sale2 = Sale(
    id: 2,
    total: 300.0,
    createdAt: DateTime(2026, 5, 11),
    items: const [saleItem],
    status: 'completed',
  );

  setUp(() {
    mockRepo = MockSalesRepository();
    provider = SalesHistoryProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Estado inicial
  // ──────────────────────────────────────────────
  group('estado inicial', () {
    test('status debe ser idle, sales vacío, selectedSale y error null', () {
      expect(provider.status, SalesHistoryStatus.idle);
      expect(provider.sales, isEmpty);
      expect(provider.selectedSale, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // loadSales
  // ──────────────────────────────────────────────
  group('loadSales', () {
    test(
      'debe transitar idle → loading → success y exponer lista de ventas',
      () async {
        when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1, sale2]);

        await provider.loadSales();

        expect(provider.status, SalesHistoryStatus.success);
        expect(provider.sales, hasLength(2));
        expect(provider.sales[0].id, 1);
        expect(provider.sales[1].id, 2);
      },
    );

    test('debe fallar con error cuando getSales lanza ApiException', () async {
      when(
        () => mockRepo.getSales(),
      ).thenThrow(const UnknownApiException('Error al cargar ventas', 500));

      await provider.loadSales();

      expect(provider.status, SalesHistoryStatus.error);
      expect(provider.errorMessage, contains('Error al cargar ventas'));
    });

    test('debe limpiar errorMessage antes de recargar', () async {
      when(
        () => mockRepo.getSales(),
      ).thenThrow(const UnknownApiException('Error previo', 500));
      await provider.loadSales();
      expect(provider.errorMessage, isNotNull);

      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1]);

      await provider.loadSales();

      expect(provider.status, SalesHistoryStatus.success);
      expect(provider.errorMessage, isNull);
    });

    test('debe retornar lista vacía cuando no hay ventas', () async {
      when(() => mockRepo.getSales()).thenAnswer((_) async => []);

      await provider.loadSales();

      expect(provider.status, SalesHistoryStatus.success);
      expect(provider.sales, isEmpty);
    });

    test('debe manejar errores genéricos (no ApiException)', () async {
      when(() => mockRepo.getSales()).thenThrow(Exception('Algo salió mal'));

      await provider.loadSales();

      expect(provider.status, SalesHistoryStatus.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // ──────────────────────────────────────────────
  // loadSaleById
  // ──────────────────────────────────────────────
  group('loadSaleById', () {
    test(
      'debe transitar idle → loading → success y exponer la venta',
      () async {
        when(() => mockRepo.getSaleById(1)).thenAnswer((_) async => sale1);

        await provider.loadSaleById(1);

        expect(provider.status, SalesHistoryStatus.success);
        expect(provider.selectedSale, isNotNull);
        expect(provider.selectedSale!.id, 1);
        expect(provider.selectedSale!.total, 500.0);
      },
    );

    test(
      'debe fallar con error cuando getSaleById lanza ApiException',
      () async {
        when(
          () => mockRepo.getSaleById(99),
        ).thenThrow(const UnknownApiException('Venta no encontrada', 404));

        await provider.loadSaleById(99);

        expect(provider.status, SalesHistoryStatus.error);
        expect(provider.errorMessage, contains('Venta no encontrada'));
      },
    );

    test('debe manejar errores genéricos en loadSaleById', () async {
      when(
        () => mockRepo.getSaleById(1),
      ).thenThrow(Exception('Error inesperado'));

      await provider.loadSaleById(1);

      expect(provider.status, SalesHistoryStatus.error);
      expect(provider.errorMessage, isNotNull);
    });
  });

  // ──────────────────────────────────────────────
  // clearError
  // ──────────────────────────────────────────────
  group('clearError', () {
    test('debe volver a idle con errorMessage null', () async {
      when(
        () => mockRepo.getSales(),
      ).thenThrow(const UnknownApiException('Error', 500));
      await provider.loadSales();
      expect(provider.status, SalesHistoryStatus.error);

      provider.clearError();

      expect(provider.status, SalesHistoryStatus.idle);
      expect(provider.errorMessage, isNull);
    });

    test('no debe fallar si no hay error previo', () {
      provider.clearError();

      expect(provider.status, SalesHistoryStatus.idle);
      expect(provider.errorMessage, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // Múltiples llamadas
  // ──────────────────────────────────────────────
  group('múltiples llamadas', () {
    test('debe recargar ventas correctamente (loadSales dos veces)', () async {
      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1]);
      await provider.loadSales();
      expect(provider.sales, hasLength(1));

      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1, sale2]);

      await provider.loadSales();

      expect(provider.status, SalesHistoryStatus.success);
      expect(provider.sales, hasLength(2));
    });

    test(
      'debe ejecutar loadSales y luego loadSaleById secuencialmente',
      () async {
        when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1, sale2]);
        when(() => mockRepo.getSaleById(1)).thenAnswer((_) async => sale1);

        await provider.loadSales();
        expect(provider.status, SalesHistoryStatus.success);
        expect(provider.sales, hasLength(2));

        await provider.loadSaleById(1);

        expect(provider.status, SalesHistoryStatus.success);
        expect(provider.selectedSale, isNotNull);
        expect(provider.selectedSale!.id, 1);
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

    test('debe llamar notifyListeners durante loadSales', () async {
      when(() => mockRepo.getSales()).thenAnswer((_) async => [sale1]);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadSales();

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners durante loadSaleById', () async {
      when(() => mockRepo.getSaleById(1)).thenAnswer((_) async => sale1);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadSaleById(1);

      expect(notifyCount, greaterThan(0));
    });

    test('debe llamar notifyListeners en clearError', () async {
      when(
        () => mockRepo.getSales(),
      ).thenThrow(const UnknownApiException('Error', 500));
      await provider.loadSales();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();

      expect(notifyCount, greaterThan(0));
    });
  });
}
