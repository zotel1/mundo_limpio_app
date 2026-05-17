// Configuraci├│n centralizada de la aplicaci├│n.
// Usa const String.fromEnvironment para leer --dart-define=BASE_URL
// y provee valores por defecto para desarrollo local.
//
// Constructor privado: esta clase no se instancia,
// solo expone constantes est├íticas.

/// Configuraci├│n global de conexi├│n con el backend.
///
/// Todas las constantes son `static const` y se resuelven
/// en tiempo de compilaci├│n. No requiere widgets de Flutter,
/// solo Dart puro.
class AppConfig {
  AppConfig._(); // Constructor privado: solo miembros est├íticos

  /// URL base de la API REST.
  ///
  /// Se overridea con `--dart-define=BASE_URL=https://api.example.com/api/v1`.
  /// Por defecto apunta a localhost para desarrollo con backend local.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// Tiempo m├íximo de espera para establecer conexi├│n TCP.
  /// 10 segundos da margen para redes lentas sin bloquear la UI.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Tiempo m├íximo de espera para recibir la respuesta completa.
  /// 10 segundos es suficiente para la mayor├¡a de las APIs REST.
  static const Duration receiveTimeout = Duration(seconds: 10);
}
