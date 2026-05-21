// Implementación concreta del repositorio de splash.
//
// Usa Dio para llamar al endpoint de salud del backend
// (GET /actuator/health). No requiere AuthInterceptor porque
// el endpoint de salud es público.
//
// No lanza excepciones: los errores se capturan y se retorna
// false para que el SplashProvider transicione a estado retry.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';

import '../domain/splash_repository.dart';

/// Implementación de [SplashRepository] que verifica la salud del backend.
///
/// Recibe una instancia de [Dio] para permitir testing con mocks.
/// En producción se inyecta un Dio configurado con [healthBaseUrl]
/// y timeouts de 30 segundos.
class SplashRepositoryImpl implements SplashRepository {
  final Dio _dio;

  /// Crea el repositorio con una instancia de [Dio] inyectada.
  ///
  /// [dio] debe estar configurado con la URL base del endpoint
  /// de salud y timeouts adecuados.
  SplashRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<bool> wakeBackend() async {
    try {
      final response = await _dio.get('/actuator/health');
      return response.statusCode == 200;
    } catch (_) {
      // No lanza: los errores se manejan como false
      return false;
    }
  }
}
