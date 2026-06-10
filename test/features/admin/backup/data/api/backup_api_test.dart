// Pruebas unitarias para BackupApi con MockDio.
//
// Cubre los 3 endpoints:
// - POST /api/v1/admin/backups → createBackup
// - GET /api/v1/admin/backups → getBackups
// - GET /api/v1/admin/backups/{id}/download → downloadBackup
//
// Cada uno se prueba con éxito y con DioException.
//
// TDD: RED — test escrito antes que la implementación

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/api/backup_api.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late BackupApi api;

  setUp(() {
    mockDio = MockDio();
    api = BackupApi(dio: mockDio);
  });

  // ──────────────────────────────────────────────
  // createBackup
  // ──────────────────────────────────────────────
  group('BackupApi — createBackup', () {
    test(
      'POST /api/v1/admin/backups → retorna BackupResponse en 200',
      () async {
        // Arrange
        final json = {
          'id': 1,
          'filename': 'backup.sql.gz',
          'size': 1024,
          'compressedSize': 512,
          'status': 'COMPLETED',
          'createdAt': '2026-06-01T10:00:00.000Z',
        };
        when(() => mockDio.post('/api/v1/admin/backups')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/api/v1/admin/backups'),
            data: json,
            statusCode: 200,
          ),
        );

        // Act
        final result = await api.createBackup();

        // Assert
        expect(result, isA<BackupResponse>());
        expect(result.id, equals(1));
        expect(result.filename, equals('backup.sql.gz'));
        expect(result.status, equals(BackupStatus.completed));
        verify(() => mockDio.post('/api/v1/admin/backups')).called(1);
      },
    );

    test('createBackup con DioException → lanza ApiException', () async {
      // Arrange
      when(() => mockDio.post('/api/v1/admin/backups')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/admin/backups'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/admin/backups'),
            statusCode: 500,
          ),
        ),
      );

      // Act & Assert
      expect(() async => api.createBackup(), throwsA(isA<ApiException>()));
    });
  });

  // ──────────────────────────────────────────────
  // getBackups
  // ──────────────────────────────────────────────
  group('BackupApi — getBackups', () {
    test('GET /api/v1/admin/backups → retorna lista en 200', () async {
      // Arrange
      final json = {
        'content': [
          {
            'id': 1,
            'filename': 'backup_1.sql.gz',
            'size': 1024,
            'compressedSize': 512,
            'status': 'COMPLETED',
            'createdAt': '2026-06-01T10:00:00.000Z',
          },
          {
            'id': 2,
            'filename': 'backup_2.sql.gz',
            'size': 2048,
            'compressedSize': 1024,
            'status': 'FAILED',
            'createdAt': '2026-06-02T10:00:00.000Z',
          },
        ],
      };
      when(() => mockDio.get('/api/v1/admin/backups')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/admin/backups'),
          data: json,
          statusCode: 200,
        ),
      );

      // Act
      final result = await api.getBackups();

      // Assert
      expect(result, isA<List<BackupResponse>>());
      expect(result, hasLength(2));
      expect(result[0].id, equals(1));
      expect(result[0].status, equals(BackupStatus.completed));
      expect(result[1].id, equals(2));
      expect(result[1].status, equals(BackupStatus.failed));
      verify(() => mockDio.get('/api/v1/admin/backups')).called(1);
    });

    test('getBackups con DioException → lanza ApiException', () async {
      // Arrange
      when(() => mockDio.get('/api/v1/admin/backups')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/admin/backups'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/admin/backups'),
            statusCode: 500,
          ),
        ),
      );

      // Act & Assert
      expect(() async => api.getBackups(), throwsA(isA<ApiException>()));
    });
  });

  // ──────────────────────────────────────────────
  // downloadBackup
  // ──────────────────────────────────────────────
  group('BackupApi — downloadBackup', () {
    test(
      'GET /api/v1/admin/backups/{id}/download → retorna Response en 200',
      () async {
        // Arrange
        const savePath = '/tmp/backup_1.sql.gz';
        when(
          () => mockDio.download('/api/v1/admin/backups/1/download', savePath),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/api/v1/admin/backups/1/download',
            ),
            statusCode: 200,
          ),
        );

        // Act
        final result = await api.downloadBackup(1, savePath);

        // Assert
        expect(result, isA<Response<dynamic>>());
        expect(result.statusCode, equals(200));
        verify(
          () => mockDio.download('/api/v1/admin/backups/1/download', savePath),
        ).called(1);
      },
    );

    test('downloadBackup con DioException → lanza ApiException', () async {
      // Arrange
      const savePath = '/tmp/backup_1.sql.gz';
      when(
        () => mockDio.download('/api/v1/admin/backups/1/download', savePath),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/api/v1/admin/backups/1/download',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/api/v1/admin/backups/1/download',
            ),
            statusCode: 500,
          ),
        ),
      );

      // Act & Assert
      expect(
        () async => api.downloadBackup(1, savePath),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
