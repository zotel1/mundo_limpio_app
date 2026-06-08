// Pantalla de revisión de recibo OCR.
//
// Muestra los datos detectados por el backend OCR en campos editables
// para que el ADMIN pueda corregir proveedor, fecha y líneas antes
// de confirmar la compra.
//
// Características:
// - Campos editables para proveedor y fecha
// - Líneas de productos con cantidad y precio unitario editables
// - Indicador visual (⚠️) para líneas con confianza < 0.3
// - Mensaje "No se detectaron productos" si lines[] está vacío
// - Mapeo name→description (R6.1) al construir el request de confirmación
// - Navegación a /receipts/confirmed tras éxito
//
// TDD: GREEN — implementación completa para pasar los tests widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/product_line_confirm_dto.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/product_line_dto.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_provider.dart';

/// Pantalla para revisar y editar los datos detectados por OCR.
///
/// Recibe [processResponse] con los datos extraídos de la imagen.
/// Permite al admin corregir proveedor, fecha y líneas antes de confirmar.
class ReceiptReviewScreen extends StatefulWidget {
  /// Datos procesados por OCR a revisar.
  final ReceiptProcessResponse processResponse;

  const ReceiptReviewScreen({super.key, required this.processResponse});

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late TextEditingController _supplierController;
  late TextEditingController _dateController;
  late List<_EditableLine> _editableLines;

  @override
  void initState() {
    super.initState();
    _supplierController = TextEditingController(
      text: widget.processResponse.detectedSupplier,
    );
    _dateController = TextEditingController(
      text: widget.processResponse.detectedDate ?? '',
    );
    _editableLines = widget.processResponse.lines
        .map(
          (line) => _EditableLine(
            nameController: TextEditingController(text: line.name),
            quantityController: TextEditingController(
              text: line.quantity.toString(),
            ),
            unitPriceController: TextEditingController(
              text: line.unitPrice.toString(),
            ),
            originalLine: line,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _dateController.dispose();
    for (final line in _editableLines) {
      line.nameController.dispose();
      line.quantityController.dispose();
      line.unitPriceController.dispose();
    }
    super.dispose();
  }

  /// Mapea ProductLineDto.name → ProductLineConfirmDto.description (R6.1).
  ReceiptConfirmRequest _buildConfirmRequest() {
    return ReceiptConfirmRequest(
      imageUrl: widget.processResponse.imageUrl,
      supplierName: _supplierController.text,
      purchaseDate: _dateController.text,
      lines: _editableLines.map((line) {
        final qty =
            int.tryParse(line.quantityController.text) ??
            line.originalLine.quantity;
        final price =
            double.tryParse(line.unitPriceController.text) ??
            line.originalLine.unitPrice;
        return ProductLineConfirmDto(
          description: line.nameController.text,
          quantity: qty,
          unitPrice: price,
          bulkProductId: line.originalLine.bulkProductId,
        );
      }).toList(),
    );
  }

  Future<void> _onConfirm() async {
    final provider = context.read<ReceiptsProvider>();
    final request = _buildConfirmRequest();
    await provider.confirmReceipt(request);

    if (!mounted) return;

    if (provider.status == ReceiptsStatus.confirmed) {
      context.push('/receipts/confirmed', extra: provider.purchaseResponse);
    }
  }

  Future<void> _onRetry() async {
    await _onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final hasLines = widget.processResponse.lines.isNotEmpty;

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Revisar Recibo'),
      body: SafeArea(
        child: Consumer<ReceiptsProvider>(
          builder: (context, provider, _) {
            if (provider.status == ReceiptsStatus.confirming) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CatLoadingIndicator.decorative(),
                    SizedBox(height: 16),
                    Text(
                      'Confirmando compra...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            if (provider.status == ReceiptsStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage ?? 'Error al confirmar',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Proveedor ─────────────────────────
                  TextField(
                    controller: _supplierController,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Fecha ─────────────────────────────
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      hintText: 'yyyy-MM-dd',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Líneas de productos ───────────────
                  if (hasLines) ...[
                    const Text(
                      'Productos detectados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildLineWidgets(),
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'No se detectaron productos',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ─── Botón Confirmar ───────────────────
                  if (hasLines)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _onConfirm,
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Confirmar Compra',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construye los widgets de líneas editables con indicadores de confianza.
  List<Widget> _buildLineWidgets() {
    return _editableLines.asMap().entries.map((entry) {
      final index = entry.key;
      final editable = entry.value;
      final original = editable.originalLine;
      final isLowConfidence = original.confidence < 0.3;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isLowConfidence ? Colors.orange.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de línea: nombre + indicador confianza
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: editable.nameController,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (isLowConfidence) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Confianza baja',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Cantidad y precio unitario
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: editable.quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: editable.unitPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Unit.',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              // Subtotal calculado
              if (index < _editableLines.length)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Confianza: ${(original.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLowConfidence ? Colors.orange : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

/// Línea editable con controladores para nombre, cantidad y precio.
class _EditableLine {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final ProductLineDto originalLine;

  const _EditableLine({
    required this.nameController,
    required this.quantityController,
    required this.unitPriceController,
    required this.originalLine,
  });
}
