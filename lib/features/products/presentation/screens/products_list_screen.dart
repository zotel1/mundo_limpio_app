// Pantalla de lista de Productos (admin CRUD).
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Muestra lista con estados: loading, loaded (con datos o vacío), error.
// Incluye FAB para crear producto, pull-to-refresh, toggle activos/todos
// y swipe-to-delete con confirmación.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/core/helpers/role_guard.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/products/presentation/providers/products_provider.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_form_screen.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_detail_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ProductsProvider>();
      if (provider.status != ProductStatus.loaded) {
        provider.loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();
    final roles = context.read<AuthProvider>().roles;
    final canWrite = RoleGuard.hasAnyRole(roles, ['ADMIN', 'STOCK_MANAGER']);

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Productos'),
      body: _buildBody(provider),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              onPressed: () => _navigateToForm(provider),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(ProductsProvider provider) {
    return Column(
      children: [
        // Toggle activos/todos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Mostrar todos'),
              Switch(
                value: _showAll,
                onChanged: (value) {
                  setState(() => _showAll = value);
                  if (value) {
                    provider.loadAllProducts();
                  } else {
                    provider.loadProducts();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(child: _buildListContent(provider)),
      ],
    );
  }

  Widget _buildListContent(ProductsProvider provider) {
    switch (provider.status) {
      case ProductStatus.initial:
      case ProductStatus.loading:
        if (provider.products.isNotEmpty) {
          return _buildProductList(provider);
        }
        return const Center(child: CatLoadingIndicator.general());

      case ProductStatus.loaded:
        if (provider.products.isEmpty) {
          return const Center(child: Text('No hay productos'));
        }
        return _buildProductList(provider);

      case ProductStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.error ?? 'Error desconocido'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showAll
                    ? provider.loadAllProducts()
                    : provider.loadProducts(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildProductList(ProductsProvider provider) {
    return RefreshIndicator(
      onRefresh: () =>
          _showAll ? provider.loadAllProducts() : provider.loadProducts(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.products.length,
        itemBuilder: (context, index) {
          final product = provider.products[index];
          return Dismissible(
            key: ValueKey(product.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar Producto'),
                  content: const Text(
                    '¿Estás seguro que querés eliminar este producto?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) {
              // Remover localmente para que Dismissible desaparezca del árbol
              provider.deleteProduct(product.id);
            },
            child: Card(
              child: ListTile(
                title: Text(product.name),
                subtitle: Text(
                  product.sku != null ? 'SKU: ${product.sku}' : 'Sin SKU',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _navigateToDetail(provider, product.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToForm(ProductsProvider provider) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProductsFormScreen()),
    );
    if (result == true && context.mounted) {
      _showAll ? provider.loadAllProducts() : provider.loadProducts();
    }
  }

  Future<void> _navigateToDetail(ProductsProvider provider, int id) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductsDetailScreen(productId: id)),
    );
    if (result == true && context.mounted) {
      _showAll ? provider.loadAllProducts() : provider.loadProducts();
    }
  }
}
