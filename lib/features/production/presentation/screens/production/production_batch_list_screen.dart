// Pantalla de historial de lotes de producción.
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Muestra lista con estados: loading, loaded (con datos o vacío), error.
// Incluye FAB para crear nuevo lote y pull-to-refresh.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/presentation/providers/production_provider.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_create_screen.dart';

class ProductionBatchListScreen extends StatefulWidget {
  const ProductionBatchListScreen({super.key});

  @override
  State<ProductionBatchListScreen> createState() =>
      _ProductionBatchListScreenState();
}

class _ProductionBatchListScreenState extends State<ProductionBatchListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ProductionProvider>();
      if (provider.status != ProductionStatus.loaded) {
        provider.getProductionBatches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductionProvider>();
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Historial de Producción'),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ProductionProvider provider) {
    switch (provider.status) {
      case ProductionStatus.initial:
      case ProductionStatus.loading:
        // Si ya tenemos datos, mantener la lista visible durante refresh
        if (provider.productionBatches.isNotEmpty) {
          return _buildBatchList(provider);
        }
        return const Center(child: CircularProgressIndicator());

      case ProductionStatus.loaded:
        if (provider.productionBatches.isEmpty) {
          return const Center(child: Text('No hay lotes de producción'));
        }
        return _buildBatchList(provider);

      case ProductionStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.error ?? 'Error desconocido'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => provider.getProductionBatches(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildBatchList(ProductionProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.getProductionBatches(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.productionBatches.length,
        itemBuilder: (context, index) {
          final batch = provider.productionBatches[index];
          return _buildBatchCard(batch);
        },
      ),
    );
  }

  Widget _buildBatchCard(ProductionBatch batch) {
    final dateStr = '${batch.date.day}/${batch.date.month}/${batch.date.year}';
    return Card(
      child: ListTile(
        title: Text('Lote #${batch.id}'),
        subtitle: Text('$dateStr — Producto: ${batch.finishedProductId}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${batch.quantityProduced} uds'),
            Text('${batch.quantityUsed} kg'),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCreate(ProductionProvider provider) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProductionCreateScreen()),
    );
    if (result == true && context.mounted) {
      provider.getProductionBatches();
    }
  }
}
