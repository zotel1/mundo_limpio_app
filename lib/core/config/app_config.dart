// Configuración centralizada de la aplicación.
// Usa const String.fromEnvironment para leer --dart-define=BASE_URL
// y provee valores por defecto para desarrollo local.
//
// Constructor privado: esta clase no se instancia,
// solo expone constantes estáticas.

/// Configuración global de conexión con el backend.
///
/// Todas las constantes son `static const` y se resuelven
/// en tiempo de compilación. No requiere widgets de Flutter,
/// solo Dart puro.
class AppConfig {
  AppConfig._(); // Constructor privado: solo miembros estáticos

  /// URL base de la API REST.
  ///
  /// Se overridea con `--dart-define=BASE_URL=https://api.example.com/api/v1`.
  /// Por defecto apunta a localhost para desarrollo con backend local.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// URL base para el endpoint de salud del backend.
  ///
  /// Apunta al host sin el path `/api/v1` porque el endpoint de salud
  /// (`/actuator/health`) es público y no requiere autenticación.
  /// Se overridea con `--dart-define=HEALTH_BASE_URL=https://api.example.com`.
  /// Por defecto apunta a localhost:8080 para desarrollo local.
  static const String healthBaseUrl = String.fromEnvironment(
    'HEALTH_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Tiempo máximo de espera para establecer conexión TCP.
  /// 45 segundos para tolerar cold starts del backend Render en free tier
  /// (~30-60s tras spin-down por inactividad de 15 min).
  static const Duration connectTimeout = Duration(seconds: 45);

  /// Tiempo máximo de espera para recibir la respuesta completa.
  /// 10 segundos es suficiente para la mayoría de las APIs REST.
  static const Duration receiveTimeout = Duration(seconds: 10);
}
