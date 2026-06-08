// Pruebas unitarias para BackupRepository con MockBackupApi.
//
// Verifica que BackupRepository delega correctamente cada operación
// a BackupApi sin transformaciones ni lógica adicional.
//
// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/admin/backup/data/api/backup_api.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/repository/backup_repository.dart';

class MockBackupApi extends Mock implements BackupApi {}

void main() {
  late MockBackupApi mockApi;
  late BackupRepository repository;

  setUp(() {
    mockApi = MockBackupApi();
    repository = BackupRepository(api: mockApi);
  });

  // ──────────────────────────────────────────────
  // createBackup
  // ──────────────────────────────────────────────
  group('BackupRepository — createBackup', () {
    test('delega a BackupApi y retorna BackupResponse', () async {
      // Arrange
      final expected = BackupResponse(
        id: 1,
        filename: 'backup.sql.gz',
        size: 1024,
        compressedSize: 512,
        status: BackupStatus.completed,
        createdAt: DateTime(2026, 6, 1),
      );
      when(() => mockApi.createBackup()).thenAnswer((_) async => expected);

      // Act
      final result = await repository.createBackup();

      // Assert
      expect(result, equals(expected));
      verify(() => mockApi.createBackup()).called(1);
    });
  });

  // ──────────────────────────────────────────────
  // getBackups
  // ──────────────────────────────────────────────
  group('BackupRepository — getBackups', () {
    test('delega a BackupApi y retorna lista', () async {
      // Arrange
      final expected = [
        BackupResponse(
          id: 1,
          filename: 'backup_1.sql.gz',
          size: 1024,
          compressedSize: 512,
          status: BackupStatus.completed,
          createdAt: DateTime(2026, 6, 1),
        ),
        BackupResponse(
          id: 2,
          filename: 'backup_2.sql.gz',
          size: 2048,
          compressedSize: 1024,
          status: BackupStatus.failed,
          createdAt: DateTime(2026, 6, 2),
        ),
      ];
      when(() => mockApi.getBackups()).thenAnswer((_) async => expected);

      // Act
      final result = await repository.getBackups();

      // Assert
      expect(result, equals(expected));
      expect(result, hasLength(2));
      verify(() => mockApi.getBackups()).called(1);
    });
  });

  // ──────────────────────────────────────────────
  // downloadBackup
  // ──────────────────────────────────────────────
  group('BackupRepository — downloadBackup', () {
    test('delega a BackupApi con id y savePath', () async {
      // Arrange
      const savePath = '/tmp/backup_1.sql.gz';
      final expected = Response(
        requestOptions: RequestOptions(
          path: '/api/v1/admin/backups/1/download',
        ),
        statusCode: 200,
      );
      when(
        () => mockApi.downloadBackup(1, savePath),
      ).thenAnswer((_) async => expected);

      // Act
      final result = await repository.downloadBackup(1, savePath);

      // Assert
      expect(result, equals(expected));
      verify(() => mockApi.downloadBackup(1, savePath)).called(1);
    });
  });
}
