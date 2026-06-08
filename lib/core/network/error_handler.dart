// Manejador centralizado de errores de API.
//
// Toma una ApiException (de cualquier subtipo) y retorna un
// mensaje en español legible para el usuario final.
//
// La UI llama a ErrorHandler.getMessage(exception) y muestra
// el resultado — nunca expone detalles técnicos al usuario.

import 'api_exception.dart';

/// Traduce excepciones de API a mensajes legibles para el usuario.
///
/// Cada subtipo de [ApiException] produce un mensaje distinto.
/// La prioridad es:
/// 1. Si el mensaje de la excepción NO es el default del subtipo →
///    se retorna el mensaje original (vino del backend)
/// 2. Si el mensaje ES el default → se aplica un mapeo más amigable
/// 3. Si el mensaje está vacío → fallback genérico
class ErrorHandler {
  ErrorHandler._();

  /// Retorna un mensaje en español para [exception].
  ///
  /// La resolución sigue este orden:
  /// - [AuthException]: si el mensaje es el default → "No autorizado — iniciá sesión..."
  /// - [ValidationException]: si el mensaje es el default → "Verificá los datos ingresados."
  /// - [ConflictException]: si el mensaje es el default → "El recurso ya existe."
  /// - [RateLimitException]: si el mensaje es el default → "Demasiados intentos. Esperá un momento."
  /// - [NetworkException]: siempre → "Sin conexión a internet..."
  /// - [ServerException]: siempre → "Error interno del servidor..."
  /// - Genérico: mensaje original o fallback si está vacío
  static String getMessage(ApiException exception) {
    if (exception is AuthException) {
      return _fromStatusCodeDefault(exception.message, [
        'No autorizado. Iniciá sesión nuevamente.',
        'Acceso denegado. No tenés permisos para esta acción.',
      ]) ? 'No autorizado — iniciá sesión nuevamente.' : exception.message;
    }
    if (exception is ValidationException) {
      return _fromStatusCodeDefault(
        exception.message,
        ['Error de validación (400).'],
      )
          ? 'Verificá los datos ingresados.'
          : exception.message;
    }
    if (exception is ConflictException) {
      return _fromStatusCodeDefault(
        exception.message,
        ['Error de conflicto (409).'],
      )
          ? 'El recurso ya existe.'
          : exception.message;
    }
    if (exception is RateLimitException) {
      return _fromStatusCodeDefault(
        exception.message,
        ['Demasiados intentos (429).'],
      )
          ? 'Demasiados intentos. Esperá un momento.'
          : exception.message;
    }
    if (exception is NetworkException) {
      return 'Sin conexión a internet — verificá tu conexión y volvé a intentar.';
    }
    if (exception is ServerException) {
      return 'Error interno del servidor — intentá de nuevo más tarde.';
    }
    // ApiException genérica: mostrar el mensaje original si no está vacío
    if (exception.message.isNotEmpty) {
      return exception.message;
    }
    return 'Error inesperado. Intentalo de nuevo.';
  }

  /// Retorna `true` si [message] es uno de los mensajes default
  /// generados por [ApiException.fromStatusCode], indicando que NO
  /// vino del backend.
  static bool _fromStatusCodeDefault(String message, List<String> defaults) {
    return defaults.contains(message);
  }
}
