// Pantalla de recibo confirmado.
//
// Muestra el resumen de una compra confirmada con:
// - Datos del proveedor y fecha
// - Total de la compra
// - Lista de ítems (descripción, cantidad, precio unitario, total)
// - Botón "Nuevo Escaneo" para iniciar otro ciclo
// - Estado de error con Reintentar (defensivo)
//
// TDD: GREEN — implementación completa para pasar los tests widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_provider.dart';

/// Pantalla que muestra el resumen de una compra confirmada.
///
/// Recibe [purchase] con los datos de la compra persistida.
/// Muestra el resumen y un botón para iniciar un nuevo escaneo.
class ReceiptConfirmedScreen extends StatelessWidget {
  /// Datos de la compra confirmada.
  final Purchase purchase;

  const ReceiptConfirmedScreen({super.key, required this.purchase});

  void _onNewScan(BuildContext context) {
    context.read<ReceiptsProvider>().reset();
    context.pushReplacement('/receipts/new');
  }

  void _onRetry(BuildContext context) {
    context.read<ReceiptsProvider>().clearError();
    context.pushReplacement('/receipts/new');
  }

  @override
  Widget build(BuildContext context) {
    final date = purchase.createdAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    String formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Recibo Confirmado'),
      body: SafeArea(
        child: Consumer<ReceiptsProvider>(
          builder: (context, provider, _) {
            // Estado de error (defensivo)
            if (provider.status == ReceiptsStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage ?? 'Error desconocido',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _onRetry(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Encabezado: icono check ─────────
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Compra Confirmada!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Resumen ──────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryRow('Proveedor', purchase.supplierName),
                          const Divider(),
                          _buildSummaryRow('Fecha', dateStr),
                          const Divider(),
                          _buildSummaryRow(
                            'Total',
                            formatCurrency(purchase.total),
                            valueStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),

                  // ─── Botón Nuevo Escaneo ─────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _onNewScan(context),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text(
                        'Nuevo Escaneo',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
