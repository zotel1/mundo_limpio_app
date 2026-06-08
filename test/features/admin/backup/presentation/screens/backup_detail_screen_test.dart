// Pruebas de widget para BackupDetailScreen.
//
// Cubre los escenarios:
// - Muestra loading al iniciar
// - Con datos: muestra filename, fechas, tamaño, botón descargar
// - Error: muestra mensaje + botón reintentar
// - Download exitoso: muestra SnackBar verde
// - Download fallido: muestra SnackBar rojo
//
// Usa BackupProvider real con MockBackupRepository.
// Usa GoRouter local (como inventory_list_screen_test.dart).
//
// TDD: RED — test escrito antes que la implementación de la pantalla

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/repository/backup_repository.dart';
import 'package:mundo_limpio_app/features/admin/backup/presentation/provider/backup_provider.dart';
import 'package:mundo_limpio_app/features/admin/backup/presentation/screens/backup_detail_screen.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

/// Crea la app de test con GoRouter.
///
/// [provider] es el BackupProvider inyectado.
/// [backupId] es el ID del backup a mostrar en la ruta.
Widget createTestApp(BackupProvider provider, {int backupId = 1}) {
  final router = GoRouter(
    initialLocation: '/admin/backups/$backupId',
    routes: [
      GoRoute(
        path: '/admin/backups/:backupId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['backupId']!);
          return ChangeNotifierProvider<BackupProvider>.value(
            value: provider,
            child: BackupDetailScreen(backupId: id),
          );
        },
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
  );
}

/// Helper para pump repetido hasta que los async tasks resuelven.
Future<void> pumpUntilSettled(WidgetTester tester, {int maxFrames = 20}) async {
  for (int i = 0; i < maxFrames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockBackupRepository mockRepo;
  late BackupProvider provider;

  final backup = BackupResponse(
    id: 1,
    filename: 'backup_20260601.sql.gz',
    size: 1048576,
    compressedSize: 524288,
    status: BackupStatus.completed,
    createdAt: DateTime(2026, 6, 1, 14, 30),
    downloadUrl: 'https://storage.example.com/backups/1.sql.gz',
  );

  setUp(() {
    mockRepo = MockBackupRepository();
    provider = BackupProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Loading
  // ──────────────────────────────────────────────
  group('BackupDetailScreen — loading', () {
    testWidgets('debe mostrar indicador de carga al iniciar', (tester) async {
      // Arrange — no completar la future para mantener loading
      final completer = Completer<List<BackupResponse>>();
      when(() => mockRepo.getBackups()).thenAnswer((_) => completer.future);

      // Act
      await tester.pumpWidget(createTestApp(provider));
      await tester.pump(); // postFrameCallback → loadBackups

      // Assert
      expect(find.byType(CatLoadingIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Éxito con datos
  // ──────────────────────────────────────────────
  group('BackupDetailScreen — éxito con datos', () {
    testWidgets('debe mostrar filename, fechas, tamaño y botón descargar', (
      tester,
    ) async {
      // Arrange
      when(() => mockRepo.getBackups()).thenAnswer((_) async => [backup]);

      // Act
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Assert
      expect(find.text('backup_20260601.sql.gz'), findsOneWidget);
      expect(find.text('1/6/2026'), findsOneWidget);
      expect(find.text('1.0 MB'), findsOneWidget);
      expect(find.text('512.0 KB'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(
        find.text('https://storage.example.com/backups/1.sql.gz'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Descargar Backup'),
        findsOneWidget,
      );
    });
  });

  // ──────────────────────────────────────────────
  // Error
  // ──────────────────────────────────────────────
  group('BackupDetailScreen — error', () {
    testWidgets('debe mostrar mensaje de error y botón reintentar', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockRepo.getBackups(),
      ).thenThrow(const ApiException('Error de conexión', 500));

      // Act
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Assert
      expect(find.textContaining('Error de conexión'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Download exitoso
  // ──────────────────────────────────────────────
  group('BackupDetailScreen — download exitoso', () {
    testWidgets('debe mostrar SnackBar verde al descargar', (tester) async {
      // Arrange
      when(() => mockRepo.getBackups()).thenAnswer((_) async => [backup]);
      when(() => mockRepo.downloadBackup(any(), any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/api/v1/admin/backups/1/download',
          ),
          statusCode: 200,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Tocar el botón y usar runAsync para que la operación async real
      // (creación de dir temporal, descarga mockeada) se complete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Descargar Backup'));
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(Colors.green));
      expect(find.textContaining('Backup descargado en:'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Download fallido
  // ──────────────────────────────────────────────
  group('BackupDetailScreen — download fallido', () {
    testWidgets('debe mostrar SnackBar rojo cuando falla descarga', (
      tester,
    ) async {
      // Arrange
      when(() => mockRepo.getBackups()).thenAnswer((_) async => [backup]);
      when(
        () => mockRepo.downloadBackup(any(), any()),
      ).thenThrow(const ApiException('Error al descargar', 500));

      // Act
      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      // Tocar el botón y usar runAsync para que la operación async real
      // (creación de dir temporal, descarga mockeada con throw) se complete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Descargar Backup'));
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(Colors.red));
      expect(
        find.textContaining('Error al descargar: Error al descargar'),
        findsOneWidget,
      );
    });
  });
}
