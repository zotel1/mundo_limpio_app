// Pantalla de detalle de venta individual.
//
// Muestra los detalles completos de una venta específica:
// - Header: ID, fecha, total
// - Items: producto, cantidad, precio unitario, subtotal por ítem
// - Fila de total
//
// Estados:
// - loading: CatLoadingIndicator centrado
// - success con datos: header + items + total
// - success sin datos: "No se encontró la venta"
// - error: mensaje + botón "Reintentar"
//
// Recibe saleId por constructor y carga los datos en initState.
// Sigue el patrón de InventoryDetailScreen y ProductsDetailScreen.
//
// TDD: GREEN — implementación que pasa los tests de SaleDetailScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_item_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_history_provider.dart';

/// Pantalla que muestra el detalle completo de una venta.
class SaleDetailScreen extends StatefulWidget {
  /// ID de la venta a consultar.
  final int saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SalesHistoryProvider>().loadSaleById(widget.saleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesHistoryProvider>();

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Detalle de Venta'),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(SalesHistoryProvider provider) {
    switch (provider.status) {
      case SalesHistoryStatus.idle:
      case SalesHistoryStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: CatLoadingIndicator.general(),
          ),
        );
      case SalesHistoryStatus.success:
        final sale = provider.selectedSale;
        if (sale == null) {
          return const Center(child: Text('No se encontró la venta'));
        }
        return _buildDetailContent(sale);
      case SalesHistoryStatus.error:
        return _buildErrorState(provider);
    }
  }

  Widget _buildDetailContent(SaleResponse sale) {
    final dateStr =
        '${sale.createdAt.day}/${sale.createdAt.month}/${sale.createdAt.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header card ─────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venta #${sale.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha: $dateStr',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total: \$${sale.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Items section ───────────────────────────────────
          Text(
            'Ítems (${sale.items.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          ...sale.items.map(_buildItemRow),
          const Divider(height: 24),

          // ── Total row ───────────────────────────────────────
          _buildTotalRow(sale),
        ],
      ),
    );
  }

  Widget _buildItemRow(SaleItemResponse item) {
    final subtotal = item.quantity * item.unitPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.quantity.toStringAsFixed(2)} x \$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(SaleResponse sale) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${sale.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SalesHistoryProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                provider.errorMessage ?? 'Error desconocido',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.read<SalesHistoryProvider>().loadSaleById(
                    widget.saleId,
                  );
                },
                child: const Text('Reintentar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
