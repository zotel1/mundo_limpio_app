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
///
/// TDD: GREEN — switch expression reemplaza if-else chain
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
    return switch (exception) {
      AuthException e =>
        _fromStatusCodeDefault(e.message, [
              'No autorizado. Iniciá sesión nuevamente.',
              'Acceso denegado. No tenés permisos para esta acción.',
            ])
            ? 'No autorizado — iniciá sesión nuevamente.'
            : e.message,
      ValidationException e =>
        _fromStatusCodeDefault(e.message, ['Error de validación (400).'])
            ? 'Verificá los datos ingresados.'
            : e.message,
      ConflictException e =>
        _fromStatusCodeDefault(e.message, ['Error de conflicto (409).'])
            ? 'El recurso ya existe.'
            : e.message,
      RateLimitException e =>
        _fromStatusCodeDefault(e.message, ['Demasiados intentos (429).'])
            ? 'Demasiados intentos. Esperá un momento.'
            : e.message,
      NetworkException _ =>
        'Sin conexión a internet — verificá tu conexión y volvé a intentar.',
      ServerException _ =>
        'Error interno del servidor — intentá de nuevo más tarde.',
      UnknownApiException e =>
        e.message.isNotEmpty
            ? e.message
            : 'Error inesperado. Intentalo de nuevo.',
    };
  }

  /// Retorna `true` si [message] es uno de los mensajes default
  /// generados por [ApiException.fromStatusCode], indicando que NO
  /// vino del backend.
  static bool _fromStatusCodeDefault(String message, List<String> defaults) {
    return defaults.contains(message);
  }
}
