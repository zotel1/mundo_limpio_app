// F├íbrica de instancias de Dio (cliente HTTP).
//
// Centraliza la creaci├│n de Dio con la configuraci├│n base:
// - URL base desde AppConfig
// - Timeouts de conexi├│n y recepci├│n
// - Interceptors compartidos (logging, auth, etc.)
//
// El AuthInterceptor se agrega desde afuera porque necesita
// dependencias que ApiClient no conoce.

import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// F├íbrica que crea y configura instancias de [Dio].
///
/// Uso t├¡pico:
/// ```dart
/// final dio = ApiClient.create();
/// final authDio = ApiClient.create(extraInterceptors: [AuthInterceptor(...)]);
/// ```
class ApiClient {
  ApiClient._();

  /// Crea una instancia de [Dio] con la configuraci├│n base.
  ///
  /// - [extraInterceptors]: interceptors adicionales (ej: AuthInterceptor)
  /// - [baseUrl]: override de la URL base (default: AppConfig.baseUrl)
  ///
  /// Siempre incluye [LogInterceptor] para debugging en desarrollo.
  static Dio create({
    List<Interceptor>? extraInterceptors,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Logging para desarrollo ÔÇö muestra requests y responses
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );

    // Interceptors adicionales (auth, manejo de errores, etc.)
    if (extraInterceptors != null) {
      dio.interceptors.addAll(extraInterceptors);
    }

    return dio;
  }
}
