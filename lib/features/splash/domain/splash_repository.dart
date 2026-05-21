// Contrato del repositorio de splash.
//
// Define la interfaz abstracta que debe implementar la capa de datos.
// La capa domain/ NO importa Flutter, Dio, ni Provider.
//
// La implementación concreta (SplashRepositoryImpl) usa Dio para
// llamar al endpoint de salud del backend.

/// Repositorio abstracto para verificar disponibilidad del backend.
///
/// Expone un único método [wakeBackend] que retorna `true` si el
/// backend responde HTTP 200 en el endpoint de salud.
abstract class SplashRepository {
  /// Llama al endpoint de salud del backend.
  ///
  /// Retorna `true` si el backend está disponible (HTTP 200).
  /// Retorna `false` si hay timeout, error de red, o código != 200.
  /// No lanza excepciones — los errores se manejan como `false`.
  Future<bool> wakeBackend();
}
