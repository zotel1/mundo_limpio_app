// Repositorio de Backups — capa de datos.
//
// Actúa como wrapper simple de [BackupApi] sin lógica adicional
// de negocio, caché, ni offline. El módulo de backups es admin-only
// y siempre requiere conexión al backend.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/features/admin/backup/data/api/backup_api.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';

/// Repositorio de Backups.
///
/// Delega todas las operaciones a [BackupApi] sin transformaciones
/// ni lógica adicional. Cada método tiene la misma firma que su
/// contraparte en la API.
class BackupRepository {
  final BackupApi _api;

  /// Crea un [BackupRepository] con la [api] inyectada.
  const BackupRepository({required BackupApi api}) : _api = api;

  /// Crea un nuevo backup en el backend.
  ///
  /// Retorna [BackupResponse] con los datos del backup creado.
  Future<BackupResponse> createBackup() => _api.createBackup();

  /// Obtiene la lista de backups desde el backend.
  ///
  /// Retorna [List<BackupResponse>] con todos los backups disponibles.
  Future<List<BackupResponse>> getBackups() => _api.getBackups();

  /// Descarga un archivo de backup.
  ///
  /// [id]: ID del backup a descargar.
  /// [savePath]: ruta local donde guardar el archivo.
  /// Retorna la [Response] de Dio con la información de la descarga.
  Future<Response> downloadBackup(int id, String savePath) =>
      _api.downloadBackup(id, savePath);
}
