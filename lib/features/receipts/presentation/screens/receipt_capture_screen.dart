// Pantalla de captura de recibo.
//
// Permite al ADMIN seleccionar una imagen de la galería o cámara,
// previsualizarla y enviarla al backend para procesamiento OCR.
//
// Estados manejados:
//   idle → botones cámara/galería
//   imageSelected → preview + botón procesar
//   processing → CircularProgressIndicator
//   processSuccess → navega a /receipts/review
//   error → mensaje de error + botón Reintentar
//
// TDD: GREEN — implementación completa para pasar los tests widget

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/provider/receipts_provider.dart';

/// Pantalla para capturar una imagen de recibo.
///
/// Flujo: seleccionar imagen de galería/cámara → previsualizar → procesar OCR.
class ReceiptCaptureScreen extends StatefulWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  State<ReceiptCaptureScreen> createState() => _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends State<ReceiptCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (!mounted) return;

    if (xfile != null) {
      context.read<ReceiptsProvider>().selectImage(xfile.path);
    }
  }

  Future<void> _onProcess() async {
    final provider = context.read<ReceiptsProvider>();
    await provider.processReceipt();

    if (!mounted) return;

    if (provider.status == ReceiptsStatus.processSuccess) {
      context.push('/receipts/review', extra: provider.processResponse);
    }
  }

  Future<void> _onRetry() async {
    final provider = context.read<ReceiptsProvider>();
    // Si tenemos imagen seleccionada, reintentar procesamiento
    if (provider.selectedImagePath != null) {
      await _onProcess();
    } else {
      // Si no hay imagen, limpiar error y volver a idle
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Escanear Recibo'),
      body: Consumer<ReceiptsProvider>(
        builder: (context, provider, _) {
          return _buildBody(provider);
        },
      ),
    );
  }

  Widget _buildBody(ReceiptsProvider provider) {
    switch (provider.status) {
      case ReceiptsStatus.idle:
        return _buildIdleBody();
      case ReceiptsStatus.imageSelected:
        return _buildImageSelectedBody(provider);
      case ReceiptsStatus.processing:
        return _buildProcessingBody();
      case ReceiptsStatus.processSuccess:
        // Mientras navega, mostrar brevemente el resultado
        return _buildProcessingBody();
      case ReceiptsStatus.error:
        return _buildErrorBody(provider);
      case ReceiptsStatus.confirming:
        return _buildProcessingBody();
      case ReceiptsStatus.confirmed:
        return _buildProcessingBody();
    }
  }

  Widget _buildIdleBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Seleccioná la fuente de la imagen',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectedBody(ReceiptsProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Vista previa de la imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(provider.selectedImagePath!),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            // Botón procesar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _onProcess,
                icon: const Icon(Icons.document_scanner),
                label: const Text(
                  'Procesar Recibo',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botón cancelar / elegir otra
            TextButton.icon(
              onPressed: () => provider.resetImage(),
              icon: const Icon(Icons.refresh),
              label: const Text('Elegir otra imagen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingBody() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CatLoadingIndicator.decorative(),
          SizedBox(height: 16),
          Text(
            'Procesando recibo...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBody(ReceiptsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => provider.clearError(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
