// Contrato abstracto del repositorio de Backups.
//
// Domain layer: NO importa Flutter, Dio, ni Provider.
// Solo tipos de Dart puro y entidades del dominio.

import 'package:mundo_limpio_app/features/admin/backup/domain/entities/backup.dart';

/// Repositorio de Backups (capa de dominio).
///
/// Define la interfaz que la capa de presentación usa para
/// listar, crear y descargar backups, sin depender de
/// implementaciones concretas de red.
abstract class BackupRepository {
  /// Crea un nuevo backup en el backend.
  ///
  /// Retorna [Backup] con los datos del backup creado.
  Future<Backup> createBackup();

  /// Obtiene la lista de backups desde el backend.
  ///
  /// Retorna [List<Backup>] con todos los backups disponibles.
  Future<List<Backup>> getBackups();

  /// Descarga un archivo de backup.
  ///
  /// [id]: ID del backup a descargar.
  /// [savePath]: ruta local donde guardar el archivo.
  Future<void> downloadBackup(int id, String savePath);
}
