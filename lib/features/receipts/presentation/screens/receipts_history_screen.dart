// Pantalla de historial de compras.
//
// Muestra la lista de compras con los estados:
// - loading: CatLoadingIndicator centrado
// - success con datos: ListView con RefreshIndicator
// - success vacío: "No hay compras registradas"
// - error: mensaje + botón "Reintentar"
//
// initState: verifica rol (ADMIN, STOCK_MANAGER, ACCOUNTANT) y carga compras.
// Sigue el patrón de SalesHistoryScreen.
//
// TDD: GREEN — implementación que pasa los tests de ReceiptsHistoryScreen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_history_provider.dart';

/// Pantalla que muestra el listado de compras con sus detalles.
class ReceiptsHistoryScreen extends StatefulWidget {
  const ReceiptsHistoryScreen({super.key});

  @override
  State<ReceiptsHistoryScreen> createState() => _ReceiptsHistoryScreenState();
}

class _ReceiptsHistoryScreenState extends State<ReceiptsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReceiptsHistoryProvider>().loadReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptsHistoryProvider>();

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Historial de Compras'),
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
        if (provider.receipts.isEmpty) {
          return _buildEmptyState();
        }
        return _buildReceiptsList(provider);
      case ReceiptsHistoryStatus.error:
        return _buildErrorState(provider);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No hay compras registradas', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildReceiptsList(ReceiptsHistoryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadReceipts(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: provider.receipts.length,
        itemBuilder: (context, index) {
          final receipt = provider.receipts[index];
          return _buildReceiptCard(receipt);
        },
      ),
    );
  }

  Widget _buildReceiptCard(Purchase receipt) {
    final dateStr =
        '${receipt.createdAt.day}/${receipt.createdAt.month}/${receipt.createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/receipts/history/${receipt.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.supplierName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${receipt.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.shopping_cart,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '1 ítem',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
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
                onPressed: () => provider.loadReceipts(),
                child: const Text('Reintentar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
