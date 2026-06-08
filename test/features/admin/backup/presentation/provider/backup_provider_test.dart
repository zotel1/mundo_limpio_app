// Pruebas unitarias para BackupProvider con MockBackupRepository.
//
// Cubre la máquina de estados de 4 estados (idle, loading, success, error)
// para las operaciones: loadBackups, createBackup, downloadBackup, clearError.
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/admin/backup/domain/entities/backup.dart';
import 'package:mundo_limpio_app/features/admin/backup/domain/repository/backup_repository.dart';
import 'package:mundo_limpio_app/features/admin/backup/presentation/provider/backup_provider.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  late MockBackupRepository mockRepo;
  late BackupProvider provider;

  final backup1 = Backup(
    id: 1,
    filename: 'backup_20260601.sql.gz',
    size: 1048576,
    compressedSize: 524288,
    status: BackupStatus.completed,
    createdAt: DateTime(2026, 6, 1),
  );

  final backup2 = Backup(
    id: 2,
    filename: 'backup_20260602.sql.gz',
    size: 2097152,
    compressedSize: 1048576,
    status: BackupStatus.failed,
    createdAt: DateTime(2026, 6, 2),
  );

  setUp(() {
    mockRepo = MockBackupRepository();
    provider = BackupProvider(mockRepo);
  });

  // ──────────────────────────────────────────────
  // loadBackups
  // ──────────────────────────────────────────────
  group('BackupProvider — loadBackups', () {
    test('con éxito → status success, backups cargados', () async {
      // Arrange
      when(
        () => mockRepo.getBackups(),
      ).thenAnswer((_) async => [backup1, backup2]);

      // Act
      await provider.loadBackups();

      // Assert
      expect(provider.status, equals(BackupProviderStatus.success));
      expect(provider.backups, hasLength(2));
      expect(provider.backups[0].filename, equals('backup_20260601.sql.gz'));
      expect(provider.backups[1].filename, equals('backup_20260602.sql.gz'));
      verify(() => mockRepo.getBackups()).called(1);
    });

    test('con ApiException → status error, mensaje seteado', () async {
      // Arrange
      when(
        () => mockRepo.getBackups(),
      ).thenThrow(const ApiException('Error del servidor', 500));

      // Act
      await provider.loadBackups();

      // Assert
      expect(provider.status, equals(BackupProviderStatus.error));
      expect(provider.errorMessage, contains('Error del servidor'));
    });

    test('con error genérico → status error, mensaje seteado', () async {
      // Arrange
      when(() => mockRepo.getBackups()).thenThrow(Exception('Algo salió mal'));

      // Act
      await provider.loadBackups();

      // Assert
      expect(provider.status, equals(BackupProviderStatus.error));
      expect(provider.errorMessage, contains('Algo salió mal'));
    });
  });

  // ──────────────────────────────────────────────
  // createBackup
  // ──────────────────────────────────────────────
  group('BackupProvider — createBackup', () {
    test(
      'con éxito → llama createBackup + getBackups, status success',
      () async {
        // Arrange
        when(() => mockRepo.createBackup()).thenAnswer((_) async => backup1);
        when(
          () => mockRepo.getBackups(),
        ).thenAnswer((_) async => [backup1, backup2]);

        // Act
        await provider.createBackup();

        // Assert
        expect(provider.status, equals(BackupProviderStatus.success));
        expect(provider.backups, hasLength(2));
        verify(() => mockRepo.createBackup()).called(1);
        verify(() => mockRepo.getBackups()).called(1);
      },
    );

    test('con ApiException → status error, mensaje seteado', () async {
      // Arrange
      when(
        () => mockRepo.createBackup(),
      ).thenThrow(const ApiException('Error al crear backup', 500));

      // Act
      await provider.createBackup();

      // Assert
      expect(provider.status, equals(BackupProviderStatus.error));
      expect(provider.errorMessage, contains('Error al crear backup'));
    });
  });

  // ──────────────────────────────────────────────
  // downloadBackup
  // ──────────────────────────────────────────────
  group('BackupProvider — downloadBackup', () {
    test('con éxito → retorna ruta, downloadedFilePath seteado', () async {
      // Arrange
      when(
        () => mockRepo.downloadBackup(any(), any()),
      ).thenAnswer((_) async {});

      // Act
      final filePath = await provider.downloadBackup(1);

      // Assert
      expect(filePath, isA<String>());
      expect(filePath, endsWith('backup_1.sql.gz'));
      expect(provider.downloadedFilePath, equals(filePath));
      expect(provider.status, equals(BackupProviderStatus.success));
      verify(() => mockRepo.downloadBackup(any(), any())).called(1);
    });

    test('con ApiException → rethrow + status error', () async {
      // Arrange
      when(
        () => mockRepo.downloadBackup(any(), any()),
      ).thenThrow(const ApiException('Error de descarga', 500));

      // Act & Assert
      await expectLater(
        provider.downloadBackup(1),
        throwsA(isA<ApiException>()),
      );
      expect(provider.status, equals(BackupProviderStatus.error));
      expect(provider.errorMessage, contains('Error de descarga'));
    });
  });

  // ──────────────────────────────────────────────
  // clearError
  // ──────────────────────────────────────────────
  group('BackupProvider — clearError', () {
    test('debe volver a idle y limpiar errorMessage', () async {
      // Arrange — primero generar un error
      when(
        () => mockRepo.getBackups(),
      ).thenThrow(const ApiException('Error', 500));
      await provider.loadBackups();
      expect(provider.status, equals(BackupProviderStatus.error));
      expect(provider.errorMessage, isNotNull);

      // Act
      provider.clearError();

      // Assert
      expect(provider.status, equals(BackupProviderStatus.idle));
      expect(provider.errorMessage, isNull);
    });
  });
}
