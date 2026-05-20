// Pantalla de revisión de recibo (placeholder).
//
// PR 4 implementará la UI completa con edición de proveedor,
// fecha, líneas de productos, indicadores de baja confianza
// y botón de confirmar.
//
// Por ahora es un placeholder mínimo que recibe ReceiptProcessResponse.

import 'package:flutter/material.dart';

import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';

/// Pantalla para revisar y editar los datos detectados por OCR.
///
/// Recibe [processResponse] con los datos extraídos de la imagen.
/// Permite al admin corregir proveedor, fecha y líneas antes de confirmar.
class ReceiptReviewScreen extends StatelessWidget {
  /// Datos procesados por OCR a revisar.
  final ReceiptProcessResponse processResponse;

  const ReceiptReviewScreen({super.key, required this.processResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar Recibo')),
      body: Center(
        child: Text('Revisión: ${processResponse.detectedSupplier}'),
      ),
    );
  }
}
