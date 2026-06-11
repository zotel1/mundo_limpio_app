// Pantalla de creación de venta.
//
// Muestra un flujo de 6 estados manejado por SalesProvider:
//   idle → loadProducts() → loading → productsLoaded → select product → loadStock(id) → loading → stockLoaded → createSale(qty) → loading → success
//   Cualquier error → error → reintentar → reset → loadProducts()
//
// Estados:
// - idle/loading: spinner centrado
// - productsLoaded: DropdownButtonFormField para seleccionar producto
// - stockLoaded: info de stock + formulario de cantidad + botón crear
// - success: navegación a SaleResultScreen
// - error: banner rojo + botón reintentar
//
// TDD: GREEN — implementación que pasa los tests de CreateSaleScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_provider.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sale_result_screen.dart';

/// Pantalla de creación de venta con flujo de selección de producto y cantidad.
class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-cargar productos al iniciar la pantalla (R5.1)
    // NOTA: el control de acceso por rol se maneja centralizadamente
    // en routeRoleMap dentro de app_router.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SalesProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  /// Maneja la creación de la venta.
  ///
  /// 1. Valida cantidad ingresada
  /// 2. Llama a SalesProvider.createSale()
  /// 3. Si éxito → navega a SaleResultScreen
  Future<void> _handleCreateSale() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SalesProvider>();
    await provider.createSale(double.parse(_quantityController.text));

    if (!mounted) return;

    if (provider.status == SalesStatus.success && provider.lastSale != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SaleResultScreen(sale: provider.lastSale!),
        ),
      );
    }
  }

  /// Reintenta el flujo desde el principio.
  ///
  /// 1. Resetea el provider a estado inicial
  /// 2. Recarga productos
  void _retry() {
    final provider = context.read<SalesProvider>();
    provider.reset();
    provider.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Nueva Venta'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildBody(provider),
        ),
      ),
    );
  }

  /// Construye el cuerpo según el estado del provider.
  Widget _buildBody(SalesProvider provider) {
    switch (provider.status) {
      case SalesStatus.idle:
      case SalesStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: CatLoadingIndicator.general(),
          ),
        );
      case SalesStatus.productsLoaded:
        return _buildProductDropdown(provider);
      case SalesStatus.stockLoaded:
        return _buildSaleForm(provider);
      case SalesStatus.success:
        // La navegación se maneja en _handleCreateSale
        return const Center(child: CatLoadingIndicator.general());
      case SalesStatus.error:
        return _buildErrorSection(provider);
    }
  }

  /// Dropdown para seleccionar producto (productsLoaded).
  Widget _buildProductDropdown(SalesProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: provider.selectedProductId,
          hint: const Text('Seleccioná un producto'),
          decoration: const InputDecoration(
            labelText: 'Producto',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.inventory_2),
          ),
          items: provider.products.map((product) {
            return DropdownMenuItem<int>(
              value: product.id,
              child: Text(product.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              context.read<SalesProvider>().loadStock(value);
            }
          },
        ),
      ],
    );
  }

  /// Formulario de cantidad y botón de crear venta (stockLoaded).
  Widget _buildSaleForm(SalesProvider provider) {
    final totalStock = provider.batches.fold<double>(
      0,
      (sum, batch) => sum + batch.currentStock,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info de stock
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock disponible: ${totalStock.toStringAsFixed(2)} unidades',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...provider.batches.map(
                    (batch) => Text('Lote #${batch.id}: ${batch.currentStock}'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Campo de cantidad
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              hintText: 'Ej: 30',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_cart),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La cantidad es requerida';
              }
              final qty = double.tryParse(value);
              if (qty == null || qty <= 0) {
                return 'Ingresá una cantidad válida mayor a 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Botón de crear venta
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: provider.status == SalesStatus.loading
                  ? null
                  : _handleCreateSale,
              child: provider.status == SalesStatus.loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CatLoadingIndicator.small(),
                    )
                  : const Text('Crear Venta', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner de error con botón reintentar.
  Widget _buildErrorSection(SalesProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner de error (mismo patrón que LoginScreen)
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

        // Botón reintentar
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _retry,
            child: const Text('Reintentar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
