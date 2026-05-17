// Jerarqu├¡a de excepciones para errores de API.
//
// ApiException es la clase base. Los subtipos representan
// categor├¡as espec├¡ficas de error HTTP/de red.
//
// Uso t├¡pico:
//   throw ApiException.fromStatusCode(401);
//   => AuthException('No autorizado')

/// Excepci├│n base para todos los errores de API.
///
/// Almacena un [message] legible para el usuario y un [code]
/// que puede ser el c├│digo HTTP original o 0 para errores de red.
class ApiException implements Exception {
  /// Crea una excepci├│n con [message] descriptivo y [code] num├®rico.
  const ApiException(this.message, this.code);

  /// Mensaje descriptivo del error, apto para mostrar al usuario.
  final String message;

  /// C├│digo de error. Para errores HTTP es el status code.
  /// Para errores de conectividad es 0.
  final int code;

  @override
  String toString() => 'ApiException($code): $message';

  /// Factory que retorna el subtipo correcto seg├║n el [statusCode] HTTP.
  ///
  /// - 401/403 ÔåÆ [AuthException]
  /// - 5xx ÔåÆ [ServerException]
  /// - 0 ÔåÆ [NetworkException]
  /// - Otros ÔåÆ [ApiException] gen├®rico
  factory ApiException.fromStatusCode(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return AuthException(
        statusCode == 401
            ? 'No autorizado. Inici├í sesi├│n nuevamente.'
            : 'Acceso denegado. No ten├®s permisos para esta acci├│n.',
      );
    }
    if (statusCode >= 500 && statusCode < 600) {
      return ServerException(
        'Error interno del servidor ($statusCode). Intentalo de nuevo m├ís tarde.',
      );
    }
    if (statusCode == 0) {
      return NetworkException(
        'Sin conexi├│n a internet. Verific├í tu conexi├│n y volv├® a intentar.',
      );
    }
    return ApiException('Error inesperado ($statusCode).', statusCode);
  }
}

  /// Error de autenticaci├│n (HTTP 401 Unauthorized o 403 Forbidden).
  ///
  /// Indica que el token falta, expir├│ o es inv├ílido.
  /// El AuthInterceptor captura esta excepci├│n para gatillar el refresh.
  class AuthException extends ApiException {
    /// El c├│digo SIEMPRE es 401 (no autorizado).
    const AuthException(String message) : super(message, 401);
  }

  /// Error de conectividad de red (sin internet, timeout, DNS).
  ///
  /// C├│digo 0 porque no hay un c├│digo HTTP asociado.
  class NetworkException extends ApiException {
    /// El c├│digo SIEMPRE es 0 (sin clasificaci├│n HTTP).
    const NetworkException(String message) : super(message, 0);
  }

  /// Error interno del servidor (HTTP 5xx).
  ///
  /// Indica que el backend fall├│. La UI debe mostrar un mensaje
  /// gen├®rico sin exponer detalles internos.
  class ServerException extends ApiException {
    /// El c├│digo SIEMPRE es 500 (error interno del servidor).
    const ServerException(String message) : super(message, 500);
  }
