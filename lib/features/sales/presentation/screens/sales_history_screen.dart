// Pantalla de historial de ventas.
//
// Muestra la lista de ventas con los estados:
// - loading: CatLoadingIndicator centrado
// - success con datos: ListView con RefreshIndicator
// - success vacío: "No hay ventas registradas"
// - error: mensaje + botón "Reintentar"
//
// initState: verifica rol (ADMIN, SALES_CLERK, ACCOUNTANT) y carga ventas.
// Sigue el patrón de ProductsListScreen e InventoryListScreen.
//
// TDD: GREEN — implementación que pasa los tests de SalesHistoryScreen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/helpers/role_guard.dart';
import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_history_provider.dart';

/// Pantalla que muestra el listado de ventas con sus detalles.
class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final roles = context.read<AuthProvider>().roles;
      if (!RoleGuard.hasAnyRole(roles, [
        'ADMIN',
        'SALES_CLERK',
        'ACCOUNTANT',
      ])) {
        context.go('/');
        return;
      }
      context.read<SalesHistoryProvider>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesHistoryProvider>();

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Historial de Ventas'),
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
        if (provider.sales.isEmpty) {
          return _buildEmptyState();
        }
        return _buildSalesList(provider);
      case SalesHistoryStatus.error:
        return _buildErrorState(provider);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No hay ventas registradas', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildSalesList(SalesHistoryProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadSales(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: provider.sales.length,
        itemBuilder: (context, index) {
          final sale = provider.sales[index];
          return _buildSaleCard(sale);
        },
      ),
    );
  }

  Widget _buildSaleCard(SaleResponse sale) {
    final dateStr =
        '${sale.createdAt.day}/${sale.createdAt.month}/${sale.createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/sales/history/${sale.id}'),
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
                      'Venta #${sale.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${sale.totalAmount.toStringAsFixed(2)}',
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
                          '${sale.items.length} ítems',
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
                onPressed: () => provider.loadSales(),
                child: const Text('Reintentar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
