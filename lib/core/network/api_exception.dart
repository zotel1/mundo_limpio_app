// Jerarquía de excepciones para errores de API.
//
// ApiException es la clase base. Los subtipos representan
// categorías específicas de error HTTP/de red.
//
// Uso típico:
//   throw ApiException.fromStatusCode(401);
//   => AuthException('No autorizado')

/// Excepción base para todos los errores de API.
///
/// Almacena un [message] legible para el usuario y un [code]
/// que puede ser el código HTTP original o 0 para errores de red.
class ApiException implements Exception {
  /// Crea una excepción con [message] descriptivo y [code] numérico.
  const ApiException(this.message, this.code);

  /// Mensaje descriptivo del error, apto para mostrar al usuario.
  final String message;

  /// Código de error. Para errores HTTP es el status code.
  /// Para errores de conectividad es 0.
  final int code;

  @override
  String toString() => 'ApiException($code): $message';

  /// Factory que retorna el subtipo correcto según el [statusCode] HTTP.
  ///
  /// - 401/403 → [AuthException]
  /// - 5xx → [ServerException]
  /// - 0 → [NetworkException]
  /// - Otros → [ApiException] genérico
  factory ApiException.fromStatusCode(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return AuthException(
        statusCode == 401
            ? 'No autorizado. Iniciá sesión nuevamente.'
            : 'Acceso denegado. No tenés permisos para esta acción.',
      );
    }
    if (statusCode >= 500 && statusCode < 600) {
      return ServerException(
        'Error interno del servidor ($statusCode). Intentalo de nuevo más tarde.',
      );
    }
    if (statusCode == 0) {
      return NetworkException(
        'Sin conexión a internet. Verificá tu conexión y volvé a intentar.',
      );
    }
    return ApiException('Error inesperado ($statusCode).', statusCode);
  }
}

/// Error de autenticación (HTTP 401 Unauthorized o 403 Forbidden).
///
/// Indica que el token falta, expiró o es inválido.
/// El AuthInterceptor captura esta excepción para gatillar el refresh.
class AuthException extends ApiException {
  /// El código SIEMPRE es 401 (no autorizado).
  const AuthException(String message) : super(message, 401);
}

/// Error de conectividad de red (sin internet, timeout, DNS).
///
/// Código 0 porque no hay un código HTTP asociado.
class NetworkException extends ApiException {
  /// El código SIEMPRE es 0 (sin clasificación HTTP).
  const NetworkException(String message) : super(message, 0);
}

/// Error interno del servidor (HTTP 5xx).
///
/// Indica que el backend falló. La UI debe mostrar un mensaje
/// genérico sin exponer detalles internos.
class ServerException extends ApiException {
  /// El código SIEMPRE es 500 (error interno del servidor).
  const ServerException(String message) : super(message, 500);
}
