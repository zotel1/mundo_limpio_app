// Pruebas unitarias para BackupResponse (DTO manual, sin .g.dart).
//
// Cubre los escenarios de parseo desde JSON:
// - Mapeo de estados COMPLETED/FAILED
// - downloadUrl presente y ausente
// - Fechas ISO 8601
// - Campos numéricos
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';

void main() {
  group('BackupResponse — fromJson', () {
    test('debe parsear status COMPLETED correctamente', () {
      // Arrange
      final json = {
        'id': 1,
        'filename': 'backup.sql.gz',
        'size': 1024,
        'compressedSize': 512,
        'status': 'COMPLETED',
        'createdAt': '2026-06-01T10:00:00.000Z',
      };

      // Act
      final response = BackupResponse.fromJson(json);

      // Assert
      expect(response.status, equals(BackupStatus.completed));
    });

    test('debe parsear status FAILED correctamente', () {
      // Arrange
      final json = {
        'id': 2,
        'filename': 'backup_failed.sql.gz',
        'size': 0,
        'compressedSize': 0,
        'status': 'FAILED',
        'createdAt': '2026-06-01T11:00:00.000Z',
      };

      // Act
      final response = BackupResponse.fromJson(json);

      // Assert
      expect(response.status, equals(BackupStatus.failed));
    });

    test('debe parsear downloadUrl cuando está presente', () {
      // Arrange
      final json = {
        'id': 3,
        'filename': 'backup.sql.gz',
        'size': 2048,
        'compressedSize': 1024,
        'status': 'COMPLETED',
        'createdAt': '2026-06-01T12:00:00.000Z',
        'downloadUrl': 'https://storage.example.com/backups/3.sql.gz',
      };

      // Act
      final response = BackupResponse.fromJson(json);

      // Assert
      expect(
        response.downloadUrl,
        equals('https://storage.example.com/backups/3.sql.gz'),
      );
    });

    test('debe parsear downloadUrl como null cuando no está presente', () {
      // Arrange
      final json = {
        'id': 4,
        'filename': 'backup.sql.gz',
        'size': 1024,
        'compressedSize': 512,
        'status': 'COMPLETED',
        'createdAt': '2026-06-01T13:00:00.000Z',
      };

      // Act
      final response = BackupResponse.fromJson(json);

      // Assert
      expect(response.downloadUrl, isNull);
    });

    test('debe parsear createdAt ISO 8601 como DateTime correcto', () {
      // Arrange
      final json = {
        'id': 5,
        'filename': 'backup.sql.gz',
        'size': 4096,
        'compressedSize': 2048,
        'status': 'COMPLETED',
        'createdAt': '2026-06-01T14:30:00.000Z',
      };

      // Act
      final response = BackupResponse.fromJson(json);

      // Assert
      expect(response.createdAt.year, equals(2026));
      expect(response.createdAt.month, equals(6));
      expect(response.createdAt.day, equals(1));
      expect(response.createdAt.hour, equals(14));
      expect(response.createdAt.minute, equals(30));
    });

    test('debe parsear campos numéricos correctamente', () {
      // Arrange
      final json = {
        'id': 100,
        'filename': 'backup_20260601.sql.gz',
        'size': 1048576,
        'compressedSize': 524288,
        'status': 'COMPLETED',
        'createdAt': '2026-06-01T15:00:00.000Z',
      };

      // Act
      final response = BackupResponse.fromJson(json);

      // Assert
      expect(response.id, equals(100));
      expect(response.size, equals(1048576));
      expect(response.compressedSize, equals(524288));
    });
  });
}
