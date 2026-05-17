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
/// Cada subtipo de [ApiException] produce un mensaje distinto:
/// - [AuthException] → "No autorizado, iniciá sesión nuevamente"
/// - [NetworkException] → "Sin conexión a internet"
/// - [ServerException] → "Error interno del servidor"
/// - Genérico → el mensaje original o un fallback
class ErrorHandler {
  ErrorHandler._();

  /// Retorna un mensaje en español para [exception].
  ///
  /// Según el tipo de excepción, el mensaje se adapta:
  /// - Si es [AuthException]: sugiere iniciar sesión de nuevo
  /// - Si es [NetworkException]: sugiere verificar la conexión
  /// - Si es [ServerException]: pide intentar más tarde
  /// - Si es [ApiException] genérico: usa el mensaje original
  /// - Si el mensaje está vacío: usa un fallback genérico
  static String getMessage(ApiException exception) {
    if (exception is AuthException) {
      return 'No autorizado — iniciá sesión nuevamente.';
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
}
