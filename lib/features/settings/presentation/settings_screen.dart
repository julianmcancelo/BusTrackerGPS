import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../data/settings_repository.dart';
import '../../backup/data/backup_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _gpsInterval = 2;
  double _minDistance = 3.0;
  double _maxAccuracy = 50.0;
  bool _autoStopEnabled = true;
  int _autoStopMinSeconds = 20;
  bool _hapticsEnabled = true;
  String _defaultExportFormat = 'GeoJSON';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    final interval = await repo.getGpsIntervalSeconds();
    final minDist = await repo.getGpsMinDistance();
    final maxAcc = await repo.getGpsMaxAccuracy();
    final autoStop = await repo.getAutoStopEnabled();
    final autoStopSec = await repo.getAutoStopMinSeconds();
    final haptics = await repo.getHapticsEnabled();
    final fmt = await repo.getDefaultExportFormat();

    setState(() {
      _gpsInterval = interval;
      _minDistance = minDist;
      _maxAccuracy = maxAcc;
      _autoStopEnabled = autoStop;
      _autoStopMinSeconds = autoStopSec;
      _hapticsEnabled = haptics;
      _defaultExportFormat = fmt;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, String value) async {
    await ref.read(settingsRepositoryProvider).setSetting(key, value);
  }

  Future<void> _createBackup() async {
    try {
      final zipFile = await BackupService.createFullBackupZip();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Backup generado: ${zipFile.path}')),
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
    if (result.isNotEmpty && result.first.path != null) {
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
                    const SnackBar(content: Text('✓ Backup verificado correctamente')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AJUSTES')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AJUSTES Y CONFIGURACIÓN'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('GPS Y CAPTURA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Intervalo de Lectura GPS'),
                  subtitle: Text('$_gpsInterval segundos'),
                  trailing: DropdownButton<int>(
                    value: _gpsInterval,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 s (Alta prec.)')),
                      DropdownMenuItem(value: 2, child: Text('2 s (Recomendado)')),
                      DropdownMenuItem(value: 5, child: Text('5 s (Equilibrado)')),
                      DropdownMenuItem(value: 10, child: Text('10 s (Ahorro)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _gpsInterval = val);
                        _saveSetting('gps_interval_seconds', val.toString());
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Distancia Mínima de Filtrado'),
                  subtitle: Text('${_minDistance.toStringAsFixed(0)} metros'),
                  trailing: Slider(
                    value: _minDistance,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    onChanged: (val) {
                      setState(() => _minDistance = val);
                      _saveSetting('gps_min_distance', val.toString());
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text('DETECCIÓN DE PARADAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Detectar Paradas Automáticamente'),
                  subtitle: const Text('Alertar cuando la unidad permanece detenida'),
                  value: _autoStopEnabled,
                  onChanged: (val) {
                    setState(() => _autoStopEnabled = val);
                    _saveSetting('auto_stop_enabled', val.toString());
                  },
                ),
                if (_autoStopEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Tiempo Mínimo de Detención'),
                    subtitle: Text('$_autoStopMinSeconds segundos'),
                    trailing: DropdownButton<int>(
                      value: _autoStopMinSeconds,
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 s')),
                        DropdownMenuItem(value: 20, child: Text('20 s')),
                        DropdownMenuItem(value: 30, child: Text('30 s')),
                        DropdownMenuItem(value: 60, child: Text('60 s')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _autoStopMinSeconds = val);
                          _saveSetting('auto_stop_min_seconds', val.toString());
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text('INTERFAZ Y FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const SizedBox(height: 8),

          Card(
            child: SwitchListTile(
              title: const Text('Vibración (Haptics)'),
              subtitle: const Text('Vibrar al marcar paradas e incidencias'),
              value: _hapticsEnabled,
              onChanged: (val) {
                setState(() => _hapticsEnabled = val);
                _saveSetting('haptics_enabled', val.toString());
              },
            ),
          ),

          const SizedBox(height: 20),
          const Text('COPIA DE SEGURIDAD (BACKUP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                    onPressed: _createBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('EXPORTAR BACKUP COMPLETO'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _restoreBackup,
                    icon: const Icon(Icons.restore),
                    label: const Text('IMPORTAR BACKUP COMPLETO'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
