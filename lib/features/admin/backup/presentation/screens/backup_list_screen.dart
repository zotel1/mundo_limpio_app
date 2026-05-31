// Pantalla de listado de backups.
//
// Muestra la lista de backups con los estados:
// - loading: CatLoadingIndicator centrado
// - success con datos: ListView con RefreshIndicator
// - success vacío: "No hay backups disponibles"
// - error: mensaje + botón "Reintentar"
//
// initState: carga la lista de backups via BackupProvider.
// Sigue el patrón de SalesHistoryScreen.
//
// TDD: GREEN — implementación que pasa los tests de BackupListScreen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/admin/backup/data/models/backup_response.dart';
import 'package:mundo_limpio_app/features/admin/backup/presentation/provider/backup_provider.dart';

/// Pantalla que muestra el listado de backups del sistema.
class BackupListScreen extends StatefulWidget {
  const BackupListScreen({super.key});

  @override
  State<BackupListScreen> createState() => _BackupListScreenState();
}

class _BackupListScreenState extends State<BackupListScreen> {
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
      appBar: const BrandedAppBar(title: 'Backups'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await provider.createBackup();
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear Backup'),
      ),
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
        if (provider.backups.isEmpty) {
          return _buildEmptyState();
        }
        return _buildBackupList(provider);
      case BackupProviderStatus.error:
        return _buildErrorState(provider);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No hay backups disponibles', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildBackupList(BackupProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadBackups(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: provider.backups.length,
        itemBuilder: (context, index) {
          final backup = provider.backups[index];
          return _buildBackupCard(backup);
        },
      ),
    );
  }

  Widget _buildBackupCard(BackupResponse backup) {
    final sizeStr = _formatFileSize(backup.compressedSize);
    final dateStr =
        '${backup.createdAt.day}/${backup.createdAt.month}/${backup.createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/admin/backups/${backup.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      backup.filename,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusBadge(backup.status),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.storage,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sizeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BackupStatus status) {
    final isCompleted = status == BackupStatus.completed;
    return Container(
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isCompleted ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
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
                onPressed: () => provider.loadBackups(),
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
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
