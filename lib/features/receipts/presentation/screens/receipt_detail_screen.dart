// Pantalla de detalle de compra individual.
//
// Muestra los detalles completos de una compra específica:
// - Header: proveedor, fecha, total
// - Items: descripción, cantidad, precio unitario, total por ítem
//
// Estados:
// - loading: CatLoadingIndicator centrado
// - success con datos: header + items
// - success sin datos: "No se encontró la compra"
// - error: mensaje + botón "Reintentar"
//
// Recibe receiptId por constructor y carga los datos en initState.
// Sigue el patrón de SaleDetailScreen.
//
// TDD: GREEN — implementación que pasa los tests de ReceiptDetailScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_item_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_history_provider.dart';

/// Pantalla que muestra el detalle completo de una compra.
class ReceiptDetailScreen extends StatefulWidget {
  /// ID de la compra a consultar.
  final int receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReceiptsHistoryProvider>().loadReceiptById(widget.receiptId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptsHistoryProvider>();

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Detalle de Compra'),
      body: SafeArea(child: _buildBody(provider)),
    );
  }

  Widget _buildBody(ReceiptsHistoryProvider provider) {
    switch (provider.status) {
      case ReceiptsHistoryStatus.idle:
      case ReceiptsHistoryStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: CatLoadingIndicator.general(),
          ),
        );
      case ReceiptsHistoryStatus.success:
        final receipt = provider.selectedReceipt;
        if (receipt == null) {
          return const Center(child: Text('No se encontró la compra'));
        }
        return _buildDetailContent(receipt);
      case ReceiptsHistoryStatus.error:
        return _buildErrorState(provider);
    }
  }

  Widget _buildDetailContent(PurchaseResponse receipt) {
    final dateStr =
        '${receipt.purchaseDate.day}/${receipt.purchaseDate.month}/${receipt.purchaseDate.year}';

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
                    receipt.supplierName,
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
                        'Total: \$${receipt.total.toStringAsFixed(2)}',
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
            'Ítems (${receipt.items.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          ...receipt.items.map(_buildItemRow),
        ],
      ),
    );
  }

  Widget _buildItemRow(PurchaseItemResponse item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
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

  Widget _buildErrorState(ReceiptsHistoryProvider provider) {
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
                  context.read<ReceiptsHistoryProvider>().loadReceiptById(
                    widget.receiptId,
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
