// Pantalla de lista de inventario con alertas de stock bajo.
//
// Muestra los productos con stock por debajo del umbral mínimo.
// Desde esta pantalla se puede navegar al detalle de cada producto
// o ver el inventario completo.
//
// Estados:
// - loading: spinner centrado
// - lowStockLoaded: lista de productos con indicador de warning
// - error: banner rojo + botón reintentar
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/provider/inventory_provider.dart';

/// Pantalla que muestra los productos con stock bajo.
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryProvider>().loadLowStock();
      }
    });
  }

  Future<void> _handleRetry() async {
    final provider = context.read<InventoryProvider>();
    provider.reset();
    await provider.loadLowStock();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Inventario'),
      body: SafeArea(child: _buildBody(provider)),
    );
  }

  Widget _buildBody(InventoryProvider provider) {
    switch (provider.status) {
      case InventoryStatus.idle:
      case InventoryStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: CatLoadingIndicator.general(),
          ),
        );
      case InventoryStatus.lowStockLoaded:
        return _buildLowStockList(provider);
      case InventoryStatus.inventoryLoaded:
      case InventoryStatus.success:
        return _buildLowStockList(provider);
      case InventoryStatus.error:
        return _buildErrorSection(provider);
    }
  }

  Widget _buildLowStockList(InventoryProvider provider) {
    final items = provider.lowStockItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título de sección
        if (items.isNotEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Productos con stock bajo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

        // Lista de low-stock items — solo construye widgets visibles
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay productos con stock bajo',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(items[index]),
                ),
        ),

        // Botón "Ver todo el inventario" (siempre visible al final)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<InventoryProvider>().loadLowStock();
              },
              icon: const Icon(Icons.inventory_2),
              label: const Text(
                'Ver todo el inventario',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Card de producto con indicador visual de low-stock.
  Widget _buildProductCard(InventoryResponse item) {
    final isCritical = item.currentStock <= item.minStockThreshold * 0.5;
    final warningColor = isCritical ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/inventory/${item.productId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador visual
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: warningColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock actual: ${item.currentStock.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Umbral mínimo: ${item.minStockThreshold.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha de navegación
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner de error con botón reintentar.
  /// Mismo patrón que otras pantallas del proyecto.
  Widget _buildErrorSection(InventoryProvider provider) {
    return Padding(
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
              onPressed: _handleRetry,
              child: const Text('Reintentar', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
