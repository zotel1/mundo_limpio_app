// Indicador de carga con imágenes de gato mascota.
//
// Reemplaza CircularProgressIndicator con imágenes temáticas de gatos
// según el contexto de la pantalla. Cada constructor nombrado mapea
// a una imagen específica del set de assets de gato.
//
// Mapeo (R7):
// - .general()    → 01_cat_standing.png   (gato parado — carga general)
// - .inventory()  → 07_cat_broom.png      (gato con escoba — inventario)
// - .small()      → 06_cat_broom_small.png (escoba chica — inline)
// - .decorative() → 03_cat_laundry.png    (gato lavando — decorativo)
//
// TDD: REFACTOR — código limpio, anotaciones y documentación final

import 'package:flutter/material.dart';

/// Widget que muestra una imagen de gato como indicador de carga.
///
/// Los constructores nombrados seleccionan la imagen correcta según
/// el contexto de uso (carga general, inventario, inline, decorativo).
class CatLoadingIndicator extends StatelessWidget {
  /// Ruta del asset de imagen a mostrar.
  final String _assetPath;

  /// Tamaño del indicador (ancho y alto, cuadrado).
  final double size;

  /// Constructor privado que recibe la ruta del asset.
  const CatLoadingIndicator._({
    super.key,
    required String assetPath,
    this.size = 80,
  }) : _assetPath = assetPath;

  /// Indicador de carga general — gato parado (01).
  ///
  /// Usar en pantallas de lista, carga de datos general.
  const CatLoadingIndicator.general({Key? key, double size = 80})
      : this._(key: key, assetPath: 'assets/images/01_cat_standing.png', size: size);

  /// Indicador de carga de inventario — gato con escoba (07).
  ///
  /// Usar en pantallas de inventario y sincronización.
  const CatLoadingIndicator.inventory({Key? key, double size = 80})
      : this._(key: key, assetPath: 'assets/images/07_cat_broom.png', size: size);

  /// Indicador de carga chico — escoba pequeña (06).
  ///
  /// Usar en botones, formularios, spinners inline.
  const CatLoadingIndicator.small({Key? key, double size = 24})
      : this._(key: key, assetPath: 'assets/images/06_cat_broom_small.png', size: size);

  /// Indicador decorativo — gato lavando ropa (03).
  ///
  /// Usar en pantallas de procesamiento de recibos, carga decorativa.
  const CatLoadingIndicator.decorative({Key? key, double size = 80})
      : this._(key: key, assetPath: 'assets/images/03_cat_laundry.png', size: size);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando...',
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
