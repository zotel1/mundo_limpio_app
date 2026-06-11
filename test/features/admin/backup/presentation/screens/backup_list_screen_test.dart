// Pruebas de widget para BackupListScreen.
//
// Cubre los escenarios:
// - Muestra indicador de carga inicialmente
// - Muestra lista de backups cuando hay datos
// - Muestra estado vacío cuando no hay backups
// - Muestra error con botón de reintentar
// - Crear backup via FAB
//
// Usa BackupProvider real con MockBackupRepository (abstracto de dominio).
//
// TDD: GREEN — implementación que pasa los tests de BackupListScreen

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/admin/backup/domain/entities/backup.dart';
import 'package:mundo_limpio_app/features/admin/backup/domain/repository/backup_repository.dart';
import 'package:mundo_limpio_app/features/admin/backup/presentation/provider/backup_provider.dart';
import 'package:mundo_limpio_app/features/admin/backup/presentation/screens/backup_list_screen.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

/// Crea la app de test con BackupProvider real y mock repository.
Widget createTestApp(BackupProvider provider) {
  return MultiProvider(
    providers: [ChangeNotifierProvider<BackupProvider>.value(value: provider)],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: const BackupListScreen(),
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
  late MockBackupRepository mockRepo;
  late BackupProvider provider;

  final backup1 = Backup(
    id: 1,
    filename: 'backup_20260501.sql.gz',
    size: 1048576,
    compressedSize: 524288,
    status: BackupStatus.completed,
    createdAt: DateTime(2026, 5, 1),
  );

  final backup2 = Backup(
    id: 2,
    filename: 'backup_20260502.sql.gz',
    size: 2097152,
    compressedSize: 1048576,
    status: BackupStatus.failed,
    createdAt: DateTime(2026, 5, 2),
  );

  setUp(() {
    mockRepo = MockBackupRepository();
    provider = BackupProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // Loading
  // ──────────────────────────────────────────────
  group('BackupListScreen — loading', () {
    testWidgets('debe mostrar indicador de carga cuando status es loading', (
      tester,
    ) async {
      when(
        () => mockRepo.getBackups(),
      ).thenAnswer((_) => Completer<List<Backup>>().future);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(CatLoadingIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Lista con datos
  // ──────────────────────────────────────────────
  group('BackupListScreen — lista con datos', () {
    testWidgets('debe mostrar lista de backups cuando hay datos', (
      tester,
    ) async {
      when(
        () => mockRepo.getBackups(),
      ).thenAnswer((_) async => [backup1, backup2]);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('backup_20260501.sql.gz'), findsOneWidget);
      expect(find.text('backup_20260502.sql.gz'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('FAILED'), findsOneWidget);
    });

    testWidgets('debe mostrar RefreshIndicator en la lista', (tester) async {
      when(() => mockRepo.getBackups()).thenAnswer((_) async => [backup1]);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Estado vacío
  // ──────────────────────────────────────────────
  group('BackupListScreen — vacío', () {
    testWidgets('debe mostrar mensaje vacío cuando no hay backups', (
      tester,
    ) async {
      when(() => mockRepo.getBackups()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.text('No hay backups disponibles'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // Error
  // ──────────────────────────────────────────────
  group('BackupListScreen — error', () {
    testWidgets('debe mostrar error y botón de reintentar cuando falla carga', (
      tester,
    ) async {
      when(
        () => mockRepo.getBackups(),
      ).thenThrow(const UnknownApiException('Error de conexión', 500));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Error de conexión'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar debe recargar backups', (tester) async {
      when(
        () => mockRepo.getBackups(),
      ).thenThrow(const UnknownApiException('Error', 500));

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.textContaining('Error'), findsOneWidget);

      when(() => mockRepo.getBackups()).thenAnswer((_) async => [backup1]);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
      await pumpUntilSettled(tester);

      expect(provider.status, BackupProviderStatus.success);
      expect(provider.backups, hasLength(1));
    });
  });

  // ──────────────────────────────────────────────
  // Crear backup
  // ──────────────────────────────────────────────
  group('BackupListScreen — crear backup', () {
    testWidgets('FAB debe crear backup cuando se presiona', (tester) async {
      when(() => mockRepo.getBackups()).thenAnswer((_) async => []);
      when(() => mockRepo.createBackup()).thenAnswer((_) async => backup1);

      await tester.pumpWidget(createTestApp(provider));
      await pumpUntilSettled(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await pumpUntilSettled(tester);

      verify(() => mockRepo.createBackup()).called(1);
    });
  });
}
