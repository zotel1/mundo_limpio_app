// Estados de la máquina de estados del splash screen.
//
// Define los cuatro estados posibles del SplashProvider:
// - idle: estado inicial, gato durmiendo
// - waking: el usuario tocó, animación + wake call en paralelo
// - retry: el backend no respondió, se muestra botón de reintentar
// - resolved: todas las condiciones cumplidas, listo para navegar

/// Estados posibles del splash screen interactivo.
enum SplashState {
  /// Estado inicial: se muestra el gato durmiendo con prompt de tap.
  idle,

  /// El usuario tocó la pantalla. Se ejecuta animación de despertar
  /// y llamada al backend en paralelo.
  waking,

  /// El backend no respondió (timeout o error). Se muestra mensaje
  /// y botón para reintentar la llamada.
  retry,

  /// Todas las condiciones cumplidas (animación, backend, auth).
  /// GoRouter usa este estado para redirigir a la pantalla correcta.
  resolved,
}
