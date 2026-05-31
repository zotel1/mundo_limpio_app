// Pantalla de detalle de backup individual.
//
// Muestra los detalles completos de un backup específico:
// - Todos los campos: filename, size, compressedSize, status, createdAt, downloadUrl
// - Botón de descarga
//
// Estados:
// - loading: CatLoadingIndicator centrado
// - success con datos: todos los campos
// - success sin datos: "No se encontró el backup"
// - error: mensaje + botón "Reintentar"
//
// Recibe backupId por constructor y carga los datos en initState.
// Sigue el patrón de SaleDetailScreen.
//
// TDD: GREEN — implementación que pasa los tests de BackupDetailScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';
import 'package:mundo_limpio_app/features/admin/backup/presentation/provider/backup_provider.dart';

/// Pantalla que muestra el detalle completo de un backup.
class BackupDetailScreen extends StatefulWidget {
  /// ID del backup a consultar.
  final int backupId;

  const BackupDetailScreen({super.key, required this.backupId});

  @override
  State<BackupDetailScreen> createState() => _BackupDetailScreenState();
}

class _BackupDetailScreenState extends State<BackupDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BackupProvider>().loadBackups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BackupProvider>();

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Detalle de Backup'),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(BackupProvider provider) {
    switch (provider.status) {
      case BackupProviderStatus.idle:
      case BackupProviderStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: CatLoadingIndicator.general(),
          ),
        );
      case BackupProviderStatus.success:
        final backup = provider.backups.cast<BackupResponse?>().firstWhere(
          (b) => b!.id == widget.backupId,
          orElse: () => null,
        );
        if (backup == null) {
          return const Center(child: Text('No se encontró el backup'));
        }
        return _buildDetailContent(backup, provider);
      case BackupProviderStatus.error:
        return _buildErrorState(provider);
    }
  }

  Widget _buildDetailContent(BackupResponse backup, BackupProvider provider) {
    final dateStr =
        '${backup.createdAt.day}/${backup.createdAt.month}/${backup.createdAt.year}';
    final sizeStr = _formatFileSize(backup.size);
    final compressedSizeStr = _formatFileSize(backup.compressedSize);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header card ─────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backup.filename,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.storage, 'Tamaño original', sizeStr),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.compress,
                    'Tamaño comprimido',
                    compressedSizeStr,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Fecha',
                    dateStr,
                    iconColor: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(backup.status),
                  if (backup.downloadUrl != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.link,
                      'URL de descarga',
                      backup.downloadUrl!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Download button ─────────────────────────────────
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleDownload(provider, backup.id),
              icon: const Icon(Icons.download),
              label: const Text('Descargar Backup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(BackupStatus status) {
    final isCompleted = status == BackupStatus.completed;
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.error,
          size: 16,
          color: isCompleted ? Colors.green.shade700 : Colors.red.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          'Estado: ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCompleted ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Text(
            status == BackupStatus.completed ? 'COMPLETED' : 'FAILED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCompleted ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDownload(BackupProvider provider, int backupId) async {
    try {
      final filePath = await provider.downloadBackup(backupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup descargado en: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: ${provider.errorMessage ?? e}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildErrorState(BackupProvider provider) {
    return Center(
      child: Padding(
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
                onPressed: () {
                  context.read<BackupProvider>().loadBackups();
                },
                child: const Text('Reintentar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
