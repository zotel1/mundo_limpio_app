// Repositorio de Backups — capa de datos.
//
// Actúa como wrapper simple de [BackupApi] sin lógica adicional
// de negocio, caché, ni offline. El módulo de backups es admin-only
// y siempre requiere conexión al backend.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/features/admin/backup/data/api/backup_api.dart';
// ignore: unused_import — necesario para la extension method toEntity()
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';
import 'package:mundo_limpio_app/features/admin/backup/domain/entities/backup.dart'
    as domain;
import 'package:mundo_limpio_app/features/admin/backup/domain/repository/backup_repository.dart';

/// Implementación concreta del repositorio de Backups.
///
/// Delega todas las operaciones a [BackupApi] sin transformaciones
/// ni lógica adicional. Cada método tiene la misma firma que su
/// contraparte en la API.
class BackupRepositoryImpl implements BackupRepository {
  final BackupApi _api;

  /// Crea un [BackupRepositoryImpl] con la [api] inyectada.
  const BackupRepositoryImpl({required BackupApi api}) : _api = api;

  /// Crea un nuevo backup en el backend.
  ///
  /// Retorna [domain.Backup] con los datos del backup creado.
  @override
  Future<domain.Backup> createBackup({CancelToken? cancelToken}) async {
    final response = await _api.createBackup(cancelToken: cancelToken);
    return response.toEntity();
  }

  /// Obtiene la lista de backups desde el backend.
  ///
  /// Retorna [List<domain.Backup>] con todos los backups disponibles.
  @override
  Future<List<domain.Backup>> getBackups({CancelToken? cancelToken}) async {
    final responses = await _api.getBackups(cancelToken: cancelToken);
    return responses.map((r) => r.toEntity()).toList();
  }

  /// Descarga un archivo de backup.
  ///
  /// [id]: ID del backup a descargar.
  /// [savePath]: ruta local donde guardar el archivo.
  /// Retorna la [Response] de Dio con la información de la descarga.
  @override
  Future<void> downloadBackup(
    int id,
    String savePath, {
    CancelToken? cancelToken,
  }) => _api.downloadBackup(id, savePath, cancelToken: cancelToken);
}
