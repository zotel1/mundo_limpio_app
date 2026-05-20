// Pantalla de captura de recibo (placeholder).
//
// PR 4 implementará la UI completa con image_picker,
// vista previa, botón de procesar y estados de carga/error.
//
// Por ahora es un placeholder mínimo para que el router compile.

import 'package:flutter/material.dart';

/// Pantalla para capturar una imagen de recibo.
///
/// Flujo: seleccionar imagen de galería/cámara → previsualizar → procesar OCR.
class ReceiptCaptureScreen extends StatelessWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Captura de Recibo')));
  }
}
