// Pantalla de lista de Materias Primas (Bulk Products).
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Muestra lista con estados: loading, loaded (con datos o vacío), error.
// Incluye FAB para crear producto y pull-to-refresh.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_form_screen.dart';

class BulkProductListScreen extends StatefulWidget {
  const BulkProductListScreen({super.key});

  @override
  State<BulkProductListScreen> createState() => _BulkProductListScreenState();
}

class _BulkProductListScreenState extends State<BulkProductListScreen> {
  @override
  void initState() {
    super.initState();
    // Post-frame callback para evitar notifyListeners durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BulkProductProvider>();
      if (provider.status != BulkProductStatus.loaded) {
        provider.getBulkProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BulkProductProvider>();
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Materias Primas'),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BulkProductProvider provider) {
    switch (provider.status) {
      case BulkProductStatus.initial:
      case BulkProductStatus.loading:
        // Si ya tenemos datos, mantener la lista visible durante refresh
        if (provider.bulkProducts.isNotEmpty) {
          return _buildProductList(provider);
        }
        return const Center(child: CatLoadingIndicator.general());

      case BulkProductStatus.loaded:
        if (provider.bulkProducts.isEmpty) {
          return const Center(child: Text('No hay materias primas'));
        }
        return _buildProductList(provider);

      case BulkProductStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.error ?? 'Error desconocido'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => provider.getBulkProducts(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildProductList(BulkProductProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.getBulkProducts(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.bulkProducts.length,
        itemBuilder: (context, index) {
          final product = provider.bulkProducts[index];
          return Card(
            child: ListTile(
              title: Text(product.name),
              subtitle: Text(
                '${product.unitOfMeasure} — Stock: ${product.stock.toStringAsFixed(1)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToForm(provider, product: product),
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToForm(
    BulkProductProvider provider, {
    BulkProduct? product,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BulkProductFormScreen(product: product),
      ),
    );
    if (result == true && context.mounted) {
      provider.getBulkProducts();
    }
  }
}
