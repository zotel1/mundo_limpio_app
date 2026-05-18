// Pantalla de detalle de inventario de un producto.
//
// Muestra la información de stock de un producto y permite
// realizar ajustes de stock mediante un diálogo.
//
// Recibe productId por constructor y carga los datos al iniciar.
//
// Estados:
// - loading: spinner centrado
// - inventoryLoaded: tarjeta con info de stock + botón ajustar
// - error: banner rojo + botón reintentar
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/features/inventory/data/models/adjustment_request.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/provider/inventory_provider.dart';

/// Pantalla de detalle de inventario de un producto.
class InventoryDetailScreen extends StatefulWidget {
  /// ID del producto a consultar.
  final int productId;

  const InventoryDetailScreen({super.key, required this.productId});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryProvider>().loadInventory(widget.productId);
      }
    });
  }

  Future<void> _handleRetry() async {
    final provider = context.read<InventoryProvider>();
    provider.reset();
    await provider.loadInventory(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          provider.currentInventory?.productName ?? 'Detalle de Inventario',
        ),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(InventoryProvider provider) {
    switch (provider.status) {
      case InventoryStatus.idle:
      case InventoryStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: CircularProgressIndicator(),
          ),
        );
      case InventoryStatus.inventoryLoaded:
      case InventoryStatus.lowStockLoaded:
      case InventoryStatus.success:
        return _buildInventoryDetail(provider);
      case InventoryStatus.error:
        return _buildErrorSection(provider);
    }
  }

  Widget _buildInventoryDetail(InventoryProvider provider) {
    final inventory = provider.currentInventory;
    if (inventory == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta con info de stock
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del producto
                  Text(
                    inventory.productName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),

                  // Stock actual
                  _buildInfoRow(
                    'Stock actual',
                    inventory.currentStock.toStringAsFixed(2),
                    Icons.inventory_2,
                  ),
                  const SizedBox(height: 12),

                  // Umbral mínimo
                  _buildInfoRow(
                    'Umbral mínimo',
                    inventory.minStockThreshold.toStringAsFixed(2),
                    Icons.trending_down,
                  ),
                  const SizedBox(height: 12),

                  // Estado
                  _buildInfoRow(
                    'Estado',
                    inventory.currentStock <= inventory.minStockThreshold
                        ? 'Stock bajo'
                        : 'Normal',
                    inventory.currentStock <= inventory.minStockThreshold
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón "Ajustar Stock"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showAdjustStockDialog(provider),
              icon: const Icon(Icons.edit),
              label: const Text(
                'Ajustar Stock',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de información con icono.
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  /// Muestra el diálogo de ajuste de stock.
  Future<void> _showAdjustStockDialog(InventoryProvider provider) async {
    final result = await showDialog<AdjustmentRequest>(
      context: context,
      builder: (dialogContext) => const _AdjustStockDialog(),
    );

    if (result != null && mounted) {
      await provider.adjustStock(widget.productId, result);

      // Refrescar detalle solo si el ajuste fue exitoso (R8.2)
      if (mounted && provider.status == InventoryStatus.success) {
        await provider.loadInventory(widget.productId);
      }
    }
  }

  /// Banner de error con botón reintentar.
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

// ---------------------------------------------------------------------------
// AdjustStockDialog — Diálogo de ajuste de stock
// ---------------------------------------------------------------------------

/// Diálogo para ajustar el stock de un producto.
///
/// Contiene:
/// - Dropdown para tipo de ajuste (ADJUSTMENT, BREAKAGE, RETURN, QUALITY_LOSS)
/// - Campo de cantidad (número > 0, obligatorio)
/// - Campo de razón (texto, obligatorio)
/// - Botones Cancelar y Confirmar
///
/// TDD: GREEN — implementación mínima para pasar los tests
class _AdjustStockDialog extends StatefulWidget {
  const _AdjustStockDialog();

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  AdjustmentType? _selectedType;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustar Stock'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo de ajuste
              DropdownButtonFormField<AdjustmentType>(
                initialValue: _selectedType,
                hint: const Text('Seleccioná un tipo'),
                decoration: const InputDecoration(
                  labelText: 'Tipo de ajuste',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: AdjustmentType.values.map((type) {
                  return DropdownMenuItem<AdjustmentType>(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
                validator: (value) {
                  if (value == null) return 'Seleccioná un tipo de ajuste';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cantidad
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej: 10 (positivo) o -5 (negativo)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La cantidad es requerida';
                  }
                  final qty = double.tryParse(value);
                  if (qty == null || qty == 0) {
                    return 'Ingresá una cantidad válida distinta de 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Razón
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Razón',
                  hintText: 'Ej: Ajuste manual de inventario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La razón es requerida';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _handleConfirm,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.parse(_quantityController.text);
    final request = AdjustmentRequest(
      type: _selectedType!,
      quantity: quantity,
      reason: _reasonController.text.trim(),
    );

    Navigator.of(context).pop(request);
  }
}
