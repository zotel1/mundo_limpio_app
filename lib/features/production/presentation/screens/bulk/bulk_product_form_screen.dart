// Pantalla de formulario para crear/editar Materias Primas.
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Modo CREATE: 3 campos (nombre, unidad, stock inicial).
// Modo EDIT: 2 campos (nombre, unidad), valores pre-cargados.
// Valida client-side, muestra loading overlay y SnackBar en error.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';

class BulkProductFormScreen extends StatefulWidget {
  final BulkProduct? product;

  const BulkProductFormScreen({super.key, this.product});

  @override
  State<BulkProductFormScreen> createState() => _BulkProductFormScreenState();
}

class _BulkProductFormScreenState extends State<BulkProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _costPerLiterController = TextEditingController();
  final _conversionRatioController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _currentStockController.text = widget.product!.currentStockLiters
          .toString();
      _costPerLiterController.text = widget.product!.costPerLiter.toString();
      _conversionRatioController.text = widget.product!.conversionRatio
          .toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentStockController.dispose();
    _costPerLiterController.dispose();
    _conversionRatioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<BulkProductProvider>();

    if (widget.product == null) {
      await provider.createBulkProduct(
        BulkProduct(
          id: 0,
          name: _nameController.text.trim(),
          currentStockLiters: double.parse(_currentStockController.text.trim()),
          costPerLiter: double.parse(_costPerLiterController.text.trim()),
          conversionRatio: double.parse(_conversionRatioController.text.trim()),
        ),
      );
    } else {
      await provider.updateBulkProduct(
        BulkProduct(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          currentStockLiters: double.parse(_currentStockController.text.trim()),
          costPerLiter: double.parse(_costPerLiterController.text.trim()),
          conversionRatio: double.parse(_conversionRatioController.text.trim()),
          active: widget.product!.active,
        ),
      );
    }

    if (!mounted) return;

    if (provider.status == BulkProductStatus.error) {
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
            title: widget.product != null
                ? 'Editar Materia Prima'
                : 'Nueva Materia Prima',
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                  controller: _currentStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Actual (litros)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El stock es requerido';
                    }
                    final stock = double.tryParse(value.trim());
                    if (stock == null || stock < 0) {
                      return 'El stock debe ser mayor o igual a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costPerLiterController,
                  decoration: const InputDecoration(
                    labelText: 'Costo por Litro',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El costo por litro es requerido';
                    }
                    final cost = double.tryParse(value.trim());
                    if (cost == null || cost <= 0) {
                      return 'El costo debe ser mayor a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _conversionRatioController,
                  decoration: const InputDecoration(
                    labelText: 'Ratio de Conversión',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El ratio de conversión es requerido';
                    }
                    final ratio = double.tryParse(value.trim());
                    if (ratio == null || ratio <= 0) {
                      return 'El ratio debe ser mayor a 0';
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
