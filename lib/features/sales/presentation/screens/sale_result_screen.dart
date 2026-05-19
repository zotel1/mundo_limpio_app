// Pantalla de resultado de venta exitosa.
//
// Muestra confirmación visual y detalles de la venta creada,
// con opciones para crear otra venta o volver al inicio.
//
// TDD: GREEN — implementación que pasa los tests de SaleResultScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_provider.dart';

/// Pantalla de confirmación de venta exitosa.
///
/// Recibe [sale] con los datos de la venta creada.
/// Ofrece acciones para crear una nueva venta o volver al inicio.
class SaleResultScreen extends StatelessWidget {
  final SaleResponse sale;

  const SaleResultScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Venta Creada'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de éxito
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),

              // Mensaje de éxito
              const Text(
                '¡Venta creada exitosamente!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Divisor
              SizedBox(
                width: double.infinity,
                child: Divider(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 16),

              // Card con detalles de la venta
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venta #${sale.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: \$${sale.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ítems:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...sale.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Lote #${item.batchId} — ${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón "Nueva Venta"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _handleNewSale(context),
                  child: const Text(
                    'Nueva Venta',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón "Volver al Inicio"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => _handleGoHome(context),
                  child: const Text(
                    'Volver al Inicio',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resetea el provider y navega hacia atrás para crear otra venta.
  void _handleNewSale(BuildContext context) {
    context.read<SalesProvider>().reset();
    Navigator.pop(context);
  }

  /// Resetea el provider y navega hacia atrás (vuelve al inicio).
  void _handleGoHome(BuildContext context) {
    context.read<SalesProvider>().reset();
    Navigator.pop(context);
  }
}
