// Provider del módulo de Backups (admin-only).
//
// Maneja 4 estados explícitos (BackupProviderStatus) para cubrir
// la carga de lista, creación y descarga de backups desde el backend.
//
// Estados:
//   idle ──loadBackups()──→ loading ──→ success | error
//   idle ──createBackup()──→ loading ──→ success | error
//   idle ──downloadBackup(id)──→ loading ──→ success | error
//   error ──clearError()──→ idle
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/admin/backup/domain/entities/backup.dart';
import 'package:mundo_limpio_app/features/admin/backup/domain/repository/backup_repository.dart';

/// Estados posibles del provider de backups.
///
/// - [idle]: estado inicial o después de clearError
/// - [loading]: operación en curso
/// - [success]: datos cargados exitosamente
/// - [error]: ocurrió un error en la operación
enum BackupProviderStatus { idle, loading, success, error }

/// Provider del módulo de Backups.
///
/// Implementa una máquina de estados de 4 estados para listar,
/// crear y descargar backups vía [BackupRepository].
///
/// Cada método sigue el patrón:
/// 1. Actualiza estado y notifica
/// 2. Ejecuta operación asíncrona
/// 3. Actualiza estado/error y notifica
class BackupProvider extends ChangeNotifier {
  final BackupRepository _repository;

  BackupProviderStatus _status = BackupProviderStatus.idle;
  List<Backup> _backups = [];
  String? _errorMessage;
  String? _downloadedFilePath;

  /// Estado actual del provider de backups.
  BackupProviderStatus get status => _status;

  /// Lista de backups cargados desde el backend.
  List<Backup> get backups => _backups;

  /// Mensaje de error actual (null si no hay error).
  String? get errorMessage => _errorMessage;

  /// Ruta del archivo descargado (null si no hay descarga reciente).
  String? get downloadedFilePath => _downloadedFilePath;

  /// Crea un [BackupProvider] con el [repository] inyectado.
  BackupProvider(this._repository);

  /// Carga la lista de backups desde el backend.
  ///
  /// Transición: idle → loading → success | error
  /// Limpia [errorMessage] antes de comenzar.
  Future<void> loadBackups() async {
    _setLoading();
    _errorMessage = null;
    try {
      _backups = await _repository.getBackups();
      _status = BackupProviderStatus.success;
    } on ApiException catch (e) {
      _status = BackupProviderStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = BackupProviderStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Crea un nuevo backup y recarga la lista.
  ///
  /// Transición: idle → loading → success | error
  /// En éxito: recarga la lista de backups automáticamente.
  Future<void> createBackup() async {
    _setLoading();
    _errorMessage = null;
    try {
      await _repository.createBackup();
      _backups = await _repository.getBackups();
      _status = BackupProviderStatus.success;
    } on ApiException catch (e) {
      _status = BackupProviderStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = BackupProviderStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Descarga un archivo de backup a un directorio temporal.
  ///
  /// [id]: ID del backup a descargar.
  /// Transición: idle → loading → success | error
  /// Retorna la ruta del archivo descargado.
  /// Relanza la excepción si ocurre un error.
  Future<String> downloadBackup(int id) async {
    _setLoading();
    _errorMessage = null;
    try {
      final tempDir = await Directory.systemTemp.createTemp('ml_backup_');
      final savePath = '${tempDir.path}backup_$id.sql.gz';
      await _repository.downloadBackup(id, savePath);
      _downloadedFilePath = savePath;
      _status = BackupProviderStatus.success;
      notifyListeners();
      return savePath;
    } on ApiException catch (e) {
      _status = BackupProviderStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _status = BackupProviderStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Limpia el mensaje de error y vuelve a idle.
  ///
  /// Transición: error → idle
  void clearError() {
    _status = BackupProviderStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Setea estado a loading y notifica.
  void _setLoading() {
    _status = BackupProviderStatus.loading;
    notifyListeners();
  }
}
