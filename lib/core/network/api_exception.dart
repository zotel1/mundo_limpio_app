// Jerarquía de excepciones para errores de API.
//
// ApiException es la clase base. Los subtipos representan
// categorías específicas de error HTTP/de red.
//
// Uso típico:
//   throw ApiException.fromStatusCode(401);
//   => AuthException('No autorizado')

import 'package:dio/dio.dart';

/// Excepción base para todos los errores de API.
///
/// Almacena un [message] legible para el usuario y un [code]
/// que puede ser el código HTTP original o 0 para errores de red.
///
/// Sellada con Dart 3 para que el compilador fuerce exhaustividad
/// en los switch expressions sobre sus subtipos.
///
/// TDD: GREEN — refactor a sealed class + switch expression
sealed class ApiException implements Exception {
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
  /// - 400 → [ValidationException]
  /// - 401/403 → [AuthException]
  /// - 409 → [ConflictException]
  /// - 429 → [RateLimitException]
  /// - 5xx → [ServerException]
  /// - 0 → [NetworkException]
  /// - Otros → [ApiException] genérico
  factory ApiException.fromStatusCode(int statusCode) {
    if (statusCode == 400) {
      return ValidationException('Error de validación (400).');
    }
    if (statusCode == 401 || statusCode == 403) {
      return AuthException(
        statusCode == 401
            ? 'No autorizado. Iniciá sesión nuevamente.'
            : 'Acceso denegado. No tenés permisos para esta acción.',
      );
    }
    if (statusCode == 409) {
      return ConflictException('Error de conflicto (409).');
    }
    if (statusCode == 429) {
      return RateLimitException('Demasiados intentos (429).');
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
    return UnknownApiException('Error inesperado ($statusCode).', statusCode);
  }

  /// Factory que construye el subtipo correcto desde un [DioException].
  ///
  /// Intenta parsear `e.response?.data` como `Map<String, dynamic>` para
  /// extraer `message` del backend. Si no hay data o falla el parseo,
  /// cae en [fromStatusCode] como fallback.
  factory ApiException.fromDioException(DioException e) {
    try {
      final data = e.response?.data as Map<String, dynamic>?;
      if (data == null) {
        return ApiException.fromStatusCode(e.response?.statusCode ?? 0);
      }
      final message = data['message'] as String? ?? '';
      final status = e.response?.statusCode ?? 0;
      return switch (status) {
        400 => ValidationException(message),
        401 || 403 => AuthException(message),
        409 => ConflictException(message),
        429 => RateLimitException(message),
        _ => ApiException.fromStatusCode(status),
      };
    } catch (_) {
      return ApiException.fromStatusCode(e.response?.statusCode ?? 0);
    }
  }
}

/// Error de autenticación (HTTP 401 Unauthorized o 403 Forbidden).
///
/// Indica que el token falta, expiró o es inválido.
/// El AuthInterceptor captura esta excepción para gatillar el refresh.
final class AuthException extends ApiException {
  /// El código SIEMPRE es 401 (no autorizado).
  const AuthException(String message) : super(message, 401);
}

/// Error de conectividad de red (sin internet, timeout, DNS).
///
/// Código 0 porque no hay un código HTTP asociado.
final class NetworkException extends ApiException {
  /// El código SIEMPRE es 0 (sin clasificación HTTP).
  const NetworkException(String message) : super(message, 0);
}

/// Error interno del servidor (HTTP 5xx).
///
/// Indica que el backend falló. La UI debe mostrar un mensaje
/// genérico sin exponer detalles internos.
final class ServerException extends ApiException {
  /// El código SIEMPRE es 500 (error interno del servidor).
  const ServerException(String message) : super(message, 500);
}

/// Error de validación (HTTP 400 Bad Request).
///
/// Indica que el backend rechazó la solicitud por datos inválidos.
/// El mensaje suele venir del backend con detalles específicos.
final class ValidationException extends ApiException {
  /// El código SIEMPRE es 400 (bad request).
  const ValidationException(String message) : super(message, 400);
}

/// Error de conflicto (HTTP 409 Conflict).
///
/// Indica que el recurso ya existe (ej: email duplicado en registro).
final class ConflictException extends ApiException {
  /// El código SIEMPRE es 409 (conflict).
  const ConflictException(String message) : super(message, 409);
}

/// Error de límite de tasa (HTTP 429 Too Many Requests).
///
/// Indica que el cliente excedió la cuota de requests.
final class RateLimitException extends ApiException {
  /// El código SIEMPRE es 429 (too many requests).
  const RateLimitException(String message) : super(message, 429);
}

/// Error desconocido o no clasificado en las categorías HTTP estándar.
///
/// Se usa como fallback cuando el código de estado no coincide
/// con ninguna de las categorías conocidas (ej: 418, 302, etc.).
/// Reemplaza la instanciación directa de ApiException que ya no
/// es posible al ser sealed.
final class UnknownApiException extends ApiException {
  /// Crea un [UnknownApiException] con [message] y [code] arbitrarios.
  const UnknownApiException(super.message, super.code);
}
