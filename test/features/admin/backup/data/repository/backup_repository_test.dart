// Pruebas unitarias para BackupRepositoryImpl con MockBackupApi.
//
// Verifica que BackupRepositoryImpl delega correctamente cada operación
// a BackupApi y convierte los DTOs a entidades de dominio.
//
// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/admin/backup/data/api/backup_api.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/repository/backup_repository.dart';
import 'package:mundo_limpio_app/features/admin/backup/domain/entities/backup.dart'
    as domain;

class MockBackupApi extends Mock implements BackupApi {}

void main() {
  late MockBackupApi mockApi;
  late BackupRepositoryImpl repository;

  setUp(() {
    mockApi = MockBackupApi();
    repository = BackupRepositoryImpl(api: mockApi);
  });

  // ──────────────────────────────────────────────
  // createBackup
  // ──────────────────────────────────────────────
  group('BackupRepositoryImpl — createBackup', () {
    test('delega a BackupApi y retorna Backup del dominio', () async {
      // Arrange
      final response = BackupResponse(
        id: 1,
        filename: 'backup.sql.gz',
        size: 1024,
        compressedSize: 512,
        status: BackupStatus.completed,
        createdAt: DateTime(2026, 6, 1),
      );
      when(() => mockApi.createBackup()).thenAnswer((_) async => response);

      // Act
      final result = await repository.createBackup();

      // Assert
      expect(result.id, equals(1));
      expect(result.filename, equals('backup.sql.gz'));
      expect(result.status, equals(domain.BackupStatus.completed));
      verify(() => mockApi.createBackup()).called(1);
    });
  });

  // ──────────────────────────────────────────────
  // getBackups
  // ──────────────────────────────────────────────
  group('BackupRepositoryImpl — getBackups', () {
    test('delega a BackupApi y retorna lista del dominio', () async {
      // Arrange
      final responses = [
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
      when(() => mockApi.getBackups()).thenAnswer((_) async => responses);

      // Act
      final result = await repository.getBackups();

      // Assert
      expect(result, hasLength(2));
      expect(result[0].id, equals(1));
      expect(result[1].id, equals(2));
      expect(result[0].status, equals(domain.BackupStatus.completed));
      expect(result[1].status, equals(domain.BackupStatus.failed));
      verify(() => mockApi.getBackups()).called(1);
    });
  });

  // ──────────────────────────────────────────────
  // downloadBackup
  // ──────────────────────────────────────────────
  group('BackupRepositoryImpl — downloadBackup', () {
    test('delega a BackupApi con id y savePath', () async {
      // Arrange
      const savePath = '/tmp/backup_1.sql.gz';
      when(() => mockApi.downloadBackup(1, savePath)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/api/v1/admin/backups/1/download',
          ),
          statusCode: 200,
        ),
      );

      // Act
      await repository.downloadBackup(1, savePath);

      // Assert
      verify(() => mockApi.downloadBackup(1, savePath)).called(1);
    });
  });
}
