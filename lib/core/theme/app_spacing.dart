// Constantes de espaciado del design system MundoLimpio.
//
// Escala basada en grid de 8dp con 5 stops:
// xs=4, sm=8, md=16, lg=24, xl=32.
//
// TDD: GREEN — implementación mínima para pasar el test

/// Espaciado canónico del design system.
///
/// Las constantes son [static const] [double] para usar directamente
/// en propiedades como `padding`, `margin` y `SizedBox`.
///
/// La escala sigue un grid de 8dp:
/// - [xs] = 4 (medio step)
/// - [sm] = 8 (1 step)
/// - [md] = 16 (2 steps — base)
/// - [lg] = 24 (3 steps)
/// - [xl] = 32 (4 steps)
class AppSpacing {
  AppSpacing._();

  /// Extra pequeño — 4dp (medio step del grid).
  static const double xs = 4.0;

  /// Pequeño — 8dp (1 step del grid).
  static const double sm = 8.0;

  /// Medio — 16dp (2 steps, espaciado base).
  static const double md = 16.0;

  /// Grande — 24dp (3 steps).
  static const double lg = 24.0;

  /// Extra grande — 32dp (4 steps).
  static const double xl = 32.0;
}
