// Pantalla de formulario para crear un lote de producción.
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Muestra un formulario guiado con:
// - ID del Producto Terminado
// - Selección de Materia Prima (dropdown)
// - Cantidad Usada
// - Cantidad Producida
// Valida client-side, muestra loading overlay y SnackBar en error.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/helpers/role_guard.dart';
import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/features/production/presentation/widgets/ratio_example_cards.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/bulk_product_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/production_provider.dart';

class ProductionCreateScreen extends StatefulWidget {
  const ProductionCreateScreen({super.key});

  @override
  State<ProductionCreateScreen> createState() => _ProductionCreateScreenState();
}

class _ProductionCreateScreenState extends State<ProductionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _finishedProductIdController = TextEditingController();
  final _quantityUsedController = TextEditingController();
  final _quantityProducedController = TextEditingController();
  int? _selectedBulkProductId;
  double? _conversionRatio;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quantityUsedController.addListener(_updateQuantityProduced);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final roles = context.read<AuthProvider>().roles;
      if (!RoleGuard.hasAnyRole(roles, ['ADMIN', 'PRODUCTION_OP'])) {
        context.go('/');
        return;
      }
      context.read<BulkProductProvider>().getBulkProducts();
    });
  }

  /// Recalcula la cantidad producida como: cantidadUsada × ratioDeConversion.
  /// Se actualiza automáticamente cuando cambia la cantidad usada o la materia prima.
  void _updateQuantityProduced() {
    final qtyUsed = double.tryParse(_quantityUsedController.text.trim());
    if (_conversionRatio != null && qtyUsed != null && qtyUsed > 0) {
      _quantityProducedController.text = (qtyUsed * _conversionRatio!)
          .toStringAsFixed(2);
    } else {
      _quantityProducedController.text = '';
    }
  }

  @override
  void dispose() {
    _quantityUsedController.removeListener(_updateQuantityProduced);
    _finishedProductIdController.dispose();
    _quantityUsedController.dispose();
    _quantityProducedController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final prodProvider = context.read<ProductionProvider>();

    await prodProvider.createProductionBatch(
      ProductionBatchRequest(
        finishedProductId: int.parse(_finishedProductIdController.text.trim()),
        bulkProductId: _selectedBulkProductId!,
        quantityUsed: double.parse(_quantityUsedController.text.trim()),
      ),
    );

    if (!mounted) return;

    if (prodProvider.status == ProductionStatus.error) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prodProvider.error ?? 'Error al guardar')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producción registrada exitosamente')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bpProvider = context.watch<BulkProductProvider>();

    return Stack(
      children: [
        Scaffold(
          appBar: const BrandedAppBar(title: 'Nueva Producción'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const RatioExampleCards(),
                  TextFormField(
                    controller: _finishedProductIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID del Producto Terminado',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El ID del producto es requerido';
                      }
                      final id = int.tryParse(value.trim());
                      if (id == null || id <= 0) {
                        return 'El ID debe ser un número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedBulkProductId,
                    decoration: const InputDecoration(
                      labelText: 'Materia Prima',
                    ),
                    items: bpProvider.bulkProducts
                        .map(
                          (product) => DropdownMenuItem<int>(
                            value: product.id,
                            child: Text(product.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBulkProductId = value;
                        _conversionRatio = value != null
                            ? bpProvider.bulkProducts
                                  .firstWhere((p) => p.id == value)
                                  .conversionRatio
                            : null;
                        _updateQuantityProduced();
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleccione una materia prima';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityUsedController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad Usada (kg/L)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La cantidad es requerida';
                      }
                      final qty = double.tryParse(value.trim());
                      if (qty == null || qty <= 0) {
                        return 'La cantidad debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityProducedController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad Producida (unidades)',
                      hintText: 'Se calcula automáticamente',
                      helperText: 'cantidad usada × ratio de conversión',
                      helperMaxLines: 2,
                    ),
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
        ),
        if (_isSaving)
          const ModalBarrier(dismissible: false, color: Colors.black26),
        if (_isSaving) const Center(child: CatLoadingIndicator.small()),
      ],
    );
  }
}
