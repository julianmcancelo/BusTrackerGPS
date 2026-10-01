import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../backup/data/backup_service.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  Future<void> _createBackup() async {
    try {
      final zipFile = await BackupService.createFullBackupZip();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup generado: ${zipFile.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear backup: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (result != null && result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final summary = await BackupService.inspectBackupZip(file);

      if (summary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo de backup no válido')),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('BACKUP ENCONTRADO'),
            content: Text(
              'Viajes: ${summary.tripCount}\n'
              'Fotos: ${summary.photoCount}\n'
              'Audios: ${summary.audioCount}\n\n'
              '¿Desea restaurar este backup?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup verificado correctamente')),
                  );
                },
                child: const Text('IMPORTAR'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4, right: 4),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copias de Seguridad')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(Icons.save_alt, 'COPIAS DE SEGURIDAD', 'Exportar e importar archivos ZIP'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 400) {
                            return Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 14)),
                                    onPressed: _createBackup,
                                    icon: const Icon(Icons.backup),
                                    label: const Text('EXPORTAR BACKUP'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                    onPressed: _restoreBackup,
                                    icon: const Icon(Icons.restore),
                                    label: const Text('IMPORTAR BACKUP'),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: _createBackup,
                                icon: const Icon(Icons.backup),
                                label: const Text('EXPORTAR BACKUP COMPLETO'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                onPressed: _restoreBackup,
                                icon: const Icon(Icons.restore),
                                label: const Text('IMPORTAR BACKUP COMPLETO'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
