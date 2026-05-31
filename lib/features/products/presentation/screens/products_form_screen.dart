// Pantalla de formulario para crear/editar Productos.
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Modo CREATE: campos sku, name, minPrice.
// Modo EDIT: valores pre-cargados, sin minPrice validation en create.
// Valida client-side, muestra loading overlay y SnackBar en error.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/presentation/providers/products_provider.dart';

class ProductsFormScreen extends StatefulWidget {
  final Product? product;
  final int? productId;

  const ProductsFormScreen({super.key, this.product, this.productId});

  @override
  State<ProductsFormScreen> createState() => _ProductsFormScreenState();
}

class _ProductsFormScreenState extends State<ProductsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _minPriceController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _skuController.text = widget.product!.sku ?? '';
      _nameController.text = widget.product!.name;
      _minPriceController.text =
          widget.product!.minPrice?.toStringAsFixed(2) ?? '';
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _minPriceController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.product != null || widget.productId != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<ProductsProvider>();

    final product = Product(
      id: widget.product?.id ?? widget.productId ?? 0,
      sku: _skuController.text.trim().isEmpty
          ? null
          : _skuController.text.trim(),
      name: _nameController.text.trim(),
      minPrice: double.tryParse(_minPriceController.text.trim()),
    );

    if (_isEditing) {
      await provider.updateProduct(product);
    } else {
      await provider.createProduct(product);
    }

    if (!mounted) return;

    if (provider.status == ProductStatus.error) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error al guardar')),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: BrandedAppBar(
            title: _isEditing ? 'Editar Producto' : 'Nuevo Producto',
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El SKU es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio Mínimo (opcional)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final price = double.tryParse(value.trim());
                      if (price == null || price < 0) {
                        return 'Debe ser un número positivo';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                ),
              ],
            ),
          ),
        ),
        if (_isSaving)
          const ModalBarrier(dismissible: false, color: Colors.black26),
        if (_isSaving) const Center(child: CatLoadingIndicator.small()),
      ],
    );
  }
}
