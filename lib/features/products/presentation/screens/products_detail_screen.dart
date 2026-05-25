// Pantalla de detalle de Producto (admin CRUD).
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Muestra información completa del producto y acciones:
// - Ver todos los campos
// - Editar → navega a formulario
// - Eliminar (soft-delete) con confirmación
// - Reactivar (si está inactivo)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/presentation/providers/products_provider.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_form_screen.dart';

class ProductsDetailScreen extends StatefulWidget {
  final int productId;

  const ProductsDetailScreen({super.key, required this.productId});

  @override
  State<ProductsDetailScreen> createState() => _ProductsDetailScreenState();
}

class _ProductsDetailScreenState extends State<ProductsDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductsProvider>().loadProduct(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsProvider>();
    return Scaffold(
      appBar: BrandedAppBar(
        title: 'Detalle del Producto',
        actions: [
          if (provider.currentProduct != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () => _navigateToEdit(provider),
            ),
            if (!provider.currentProduct!.active)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reactivar',
                onPressed: () => _confirmReactivate(provider),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Eliminar',
                onPressed: () => _confirmDelete(provider),
              ),
          ],
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(ProductsProvider provider) {
    switch (provider.status) {
      case ProductStatus.initial:
      case ProductStatus.loading:
        return const Center(child: CatLoadingIndicator.general());

      case ProductStatus.loaded:
        final product = provider.currentProduct;
        if (product == null) {
          return const Center(child: Text('Producto no encontrado'));
        }
        return _buildDetailContent(product);

      case ProductStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.error ?? 'Error desconocido'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => provider.loadProduct(widget.productId),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDetailContent(Product product) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField('ID', product.id.toString()),
          _buildField('SKU', product.sku ?? 'Sin SKU'),
          _buildField('Nombre', product.name),
          _buildField(
            'Precio Mínimo',
            product.minPrice?.toStringAsFixed(2) ?? 'Sin precio mínimo',
          ),
          _buildField('Estado', product.active ? 'Activo' : 'Inactivo'),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ProductsProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Estás seguro que querés eliminar este producto?'),
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

    if (confirmed == true && mounted) {
      await provider.deleteProduct(widget.productId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _confirmReactivate(ProductsProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivar Producto'),
        content: const Text(
          '¿Estás seguro que querés reactivar este producto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.reactivateProduct(widget.productId);
      if (context.mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _navigateToEdit(ProductsProvider provider) async {
    final product = provider.currentProduct;
    if (product == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductsFormScreen(product: product)),
    );
    if (result == true && context.mounted) {
      provider.loadProduct(widget.productId);
    }
  }
}
