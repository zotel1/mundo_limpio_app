// Pantalla de recibo confirmado (placeholder).
//
// PR 4 implementará la UI completa con resumen de compra,
// lista de ítems, total y botón "Nuevo Escaneo".
//
// Por ahora es un placeholder mínimo que recibe PurchaseResponse.

import 'package:flutter/material.dart';

import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';

/// Pantalla que muestra el resumen de una compra confirmada.
///
/// Recibe [purchase] con los datos de la compra persistida.
/// Muestra el resumen y un botón para iniciar un nuevo escaneo.
class ReceiptConfirmedScreen extends StatelessWidget {
  /// Datos de la compra confirmada.
  final PurchaseResponse purchase;

  const ReceiptConfirmedScreen({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recibo Confirmado')),
      body: Center(
        child: Text('Compra #${purchase.id}: ${purchase.supplierName}'),
      ),
    );
  }
}
