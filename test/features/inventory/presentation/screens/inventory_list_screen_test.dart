// Pruebas de widget para InventoryListScreen.
//
// Cubre los 4 escenarios de R6:
// - R6.1: Muestra lista de low-stock items con indicadores
// - R6.2: Muestra spinner mientras carga
// - R6.3: Muestra error con botón reintentar
// - R6.4: Tap en item navega a detalle
//
// Usa InventoryProvider real con MockInventoryRepository.
//
// TDD: RED — test escrito antes que la implementación de la pantalla

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/domain/repository/inventory_repository.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/provider/inventory_provider.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_detail_screen.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

/// Crea la app de test con GoRouter para probar navegación.
///
/// [provider] es el provider de inventario inyectado.
/// [initialLocation] permite arrancar desde una ruta específica.
Widget createTestApp(
  InventoryProvider provider, {
  String initialLocation = '/',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => ChangeNotifierProvider<InventoryProvider>.value(
          value: provider,
          child: const InventoryListScreen(),
        ),
      ),
      GoRoute(
        path: '/inventory/:productId',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['productId']!);
          return ChangeNotifierProvider<InventoryProvider>.value(
            value: provider,
            child: InventoryDetailScreen(productId: productId),
          );
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
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

  const lowStockItem1 = InventoryResponse(
    productId: 1,
    productName: 'Jabón Líquido',
    currentStock: 3.0,
    minStockThreshold: 10.0,
  );
  const lowStockItem2 = InventoryResponse(
    productId: 2,
    productName: 'Detergente',
    currentStock: 5.0,
    minStockThreshold: 20.0,
  );
  final lowStockItems = [lowStockItem1, lowStockItem2];

  setUp(() {
    mockRepo = MockInventoryRepository();
    provider = InventoryProvider(repository: mockRepo);
  });

  // ──────────────────────────────────────────────
  // R6.1: Muestra lista de low-stock items
  // ──────────────────────────────────────────────
  group('InventoryListScreen — R6.1: Low-stock list', () {
    testWidgets('debe mostrar lista de low-stock items con indicadores', (
      tester,
    ) async {
      when(() => mockRepo.getLowStock()).thenAnswer((_) async => lowStockItems);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Debe mostrar ambos items
      expect(find.text('Jabón Líquido'), findsOneWidget);
      expect(find.text('Detergente'), findsOneWidget);

      // Debe mostrar stock actual y umbral
      expect(find.textContaining('3.0'), findsOneWidget);
      expect(find.textContaining('5.0'), findsOneWidget);

      // Debe mostrar indicador de warning (icono rojo/amarillo)
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    });
  });

  // ──────────────────────────────────────────────
  // R6.2: Spinner durante carga
  // ──────────────────────────────────────────────
  group('InventoryListScreen — R6.2: Loading spinner', () {
    testWidgets('debe mostrar spinner mientras carga low-stock', (
      tester,
    ) async {
      final completer = Completer<List<InventoryResponse>>();
      when(() => mockRepo.getLowStock()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestApp(provider));
      // Un frame para que initState → loadLowStock → loading
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(lowStockItems);
    });
  });

  // ──────────────────────────────────────────────
  // R6.3: Error con reintentar
  // ──────────────────────────────────────────────
  group('InventoryListScreen — R6.3: Error state', () {
    testWidgets('debe mostrar error con botón reintentar', (tester) async {
      when(
        () => mockRepo.getLowStock(),
      ).thenThrow(const ApiException('Error del servidor', 500));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Debe mostrar mensaje de error
      expect(find.textContaining('Error del servidor'), findsOneWidget);

      // Debe mostrar botón reintentar
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });

    testWidgets('reintentar debe recargar low-stock', (tester) async {
      // Arrange: falla primero
      when(
        () => mockRepo.getLowStock(),
      ).thenThrow(const ApiException('Error', 500));
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);
      expect(find.textContaining('Error'), findsOneWidget);

      // Arrange: éxito después
      when(() => mockRepo.getLowStock()).thenAnswer((_) async => lowStockItems);

      // Act: tocar reintentar
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
      await pumpUntilSettled(tester);

      // Assert: ahora muestra la lista
      expect(find.text('Jabón Líquido'), findsOneWidget);
      expect(find.text('Detergente'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // R6.4: Navegación a detalle
  // ──────────────────────────────────────────────
  group('InventoryListScreen — R6.4: Navigation', () {
    testWidgets('tap en item navega a InventoryDetailScreen', (tester) async {
      when(() => mockRepo.getLowStock()).thenAnswer((_) async => lowStockItems);
      // Stub getInventory para que el detail screen no falle al cargar
      when(
        () => mockRepo.getInventory(any()),
      ).thenAnswer((_) async => lowStockItem1);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Tap en el primer item de la lista
      await tester.tap(find.text('Jabón Líquido'));
      await pumpUntilSettled(tester);

      // Debe mostrar InventoryDetailScreen
      expect(find.byType(InventoryDetailScreen), findsOneWidget);
      expect(find.byType(InventoryListScreen), findsNothing);
    });
  });
}
