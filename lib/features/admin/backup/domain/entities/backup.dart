// Entidad de dominio que representa un backup del sistema.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo dart:core y enums puros.

/// Estado de un backup en el dominio.
///
/// - [completed]: backup generado exitosamente.
/// - [failed]: error durante la generación.
enum BackupStatus { completed, failed }

/// Backup del sistema.
///
/// Contiene los metadatos del backup: ID, nombre de archivo,
/// tamaños, estado, fecha de creación y URL de descarga opcional.
class Backup {
  /// ID único del backup.
  final int id;

  /// Nombre del archivo de backup.
  final String filename;

  /// Tamaño sin comprimir en bytes.
  final int size;

  /// Tamaño comprimido en bytes.
  final int compressedSize;

  /// Estado del backup.
  final BackupStatus status;

  /// Fecha y hora de creación del backup.
  final DateTime createdAt;

  /// URL para descargar el archivo (opcional hasta que se complete).
  final String? downloadUrl;

  /// Crea un [Backup] con todos los campos requeridos.
  const Backup({
    required this.id,
    required this.filename,
    required this.size,
    required this.compressedSize,
    required this.status,
    required this.createdAt,
    this.downloadUrl,
  });

  /// Retorna una copia con los campos indicados reemplazados.
  Backup copyWith({
    int? id,
    String? filename,
    int? size,
    int? compressedSize,
    BackupStatus? status,
    DateTime? createdAt,
    String? downloadUrl,
  }) {
    return Backup(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      size: size ?? this.size,
      compressedSize: compressedSize ?? this.compressedSize,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Backup &&
        other.id == id &&
        other.filename == filename &&
        other.size == size &&
        other.compressedSize == compressedSize &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.downloadUrl == downloadUrl;
  }

  @override
  int get hashCode => Object.hash(
    id,
    filename,
    size,
    compressedSize,
    status,
    createdAt,
    downloadUrl,
  );

  @override
  String toString() =>
      'Backup(id: $id, filename: $filename, size: $size, '
      'compressedSize: $compressedSize, status: $status, '
      'createdAt: $createdAt, downloadUrl: $downloadUrl)';
}
