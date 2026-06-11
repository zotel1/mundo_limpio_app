// Capa de comunicación HTTP para el módulo de Backups.
//
// Implementa las llamadas a los endpoints de backups del backend:
// - POST /api/v1/admin/backups
// - GET /api/v1/admin/backups
// - GET /api/v1/admin/backups/{id}/download
//
// Recibe una instancia de Dio inyectada (sin crearla internamente)
// para permitir tests con mocks y compartir la configuración
// de ApiClient (base URL, timeouts, interceptors).
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';

/// Cliente HTTP para los endpoints del módulo de Backups.
///
/// Cada método retorna su tipo correspondiente o lanza [ApiException]
/// (o subtipo) en caso de error.
///
/// Los errores HTTP se convierten con [ApiException.fromDioException]:
/// - 401/403 → [AuthException]
/// - 5xx → [ServerException]
/// - 0 (red) → [NetworkException]
class BackupApi {
  final Dio _dio;

  /// Crea un [BackupApi] con la instancia de [Dio] inyectada.
  ///
  /// [dio] debe estar configurado con la base URL y headers
  /// base (Content-Type, Accept) — ver ApiClient.create().
  const BackupApi({required Dio dio}) : _dio = dio;

  /// Crea un nuevo backup en el backend.
  ///
  /// Endpoint: `POST /api/v1/admin/backups`
  /// Retorna el [BackupResponse] del backup creado.
  Future<BackupResponse> createBackup() async {
    try {
      final response = await _dio.post('/api/v1/admin/backups');
      return BackupResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Obtiene la lista paginada de backups.
  ///
  /// Endpoint: `GET /api/v1/admin/backups`
  /// Retorna la lista de [BackupResponse] desde el campo `content`
  /// de la respuesta paginada del backend.
  Future<List<BackupResponse>> getBackups() async {
    try {
      final response = await _dio.get('/api/v1/admin/backups');
      final List<dynamic> data = response.data['content'] as List<dynamic>;
      return data
          .map((json) => BackupResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Descarga un archivo de backup.
  ///
  /// Endpoint: `GET /api/v1/admin/backups/{id}/download`
  /// [id]: ID del backup a descargar.
  /// [savePath]: ruta local donde guardar el archivo.
  /// Retorna la [Response] de Dio con la información de la descarga.
  Future<Response<dynamic>> downloadBackup(int id, String savePath) async {
    try {
      return await _dio.download(
        '/api/v1/admin/backups/$id/download',
        savePath,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
