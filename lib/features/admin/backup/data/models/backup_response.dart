// Modelo DTO para la respuesta de un backup del backend.
//
// Mapea directamente el JSON del endpoint `GET /api/v1/admin/backups`.
// No necesita .g.dart porque el mapeo es simple y directo.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:mundo_limpio_app/features/admin/backup/domain/entities/backup.dart'
    as domain;

/// Estado de un backup en el backend.
///
/// Mapea el enum Java `BackupStatus`:
/// - `COMPLETED` → [BackupStatus.completed]
/// - `FAILED` → [BackupStatus.failed]
enum BackupStatus { completed, failed }

/// Respuesta del backend con los datos de un backup.
///
/// Coincide con el record Java `BackupResponse` del backend.
/// Es un DTO de solo lectura: no necesita `toJson()`.
class BackupResponse {
  /// ID único del backup.
  final int id;

  /// Nombre del archivo de backup.
  final String filename;

  /// Tamaño sin comprimir en bytes.
  final int size;

  /// Tamaño comprimido en bytes.
  final int compressedSize;

  /// Estado del backup (COMPLETED | FAILED).
  final BackupStatus status;

  /// Fecha y hora ISO 8601 de creación del backup.
  final DateTime createdAt;

  /// URL para descargar el archivo (opcional hasta que se complete).
  final String? downloadUrl;

  /// Crea un [BackupResponse] con todos los campos requeridos.
  const BackupResponse({
    required this.id,
    required this.filename,
    required this.size,
    required this.compressedSize,
    required this.status,
    required this.createdAt,
    this.downloadUrl,
  });

  /// Construye un [BackupResponse] desde un mapa JSON.
  factory BackupResponse.fromJson(Map<String, dynamic> json) {
    return BackupResponse(
      id: json['id'] as int,
      filename: json['filename'] as String,
      size: json['size'] as int,
      compressedSize: json['compressedSize'] as int,
      status: json['status'] == 'COMPLETED'
          ? BackupStatus.completed
          : BackupStatus.failed,
      createdAt: DateTime.parse(json['createdAt'] as String),
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  /// Convierte este DTO a la entidad de dominio [domain.Backup].
  domain.Backup toEntity() => domain.Backup(
    id: id,
    filename: filename,
    size: size,
    compressedSize: compressedSize,
    status: status == BackupStatus.completed
        ? domain.BackupStatus.completed
        : domain.BackupStatus.failed,
    createdAt: createdAt,
    downloadUrl: downloadUrl,
  );
}
