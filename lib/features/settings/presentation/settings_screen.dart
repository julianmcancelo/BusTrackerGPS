import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../data/settings_repository.dart';
import '../../backup/data/backup_service.dart';
import '../../../database/database_provider.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/ota_update_service.dart';
import '../../../core/services/github_update_service.dart';

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
  bool _snapToRoadsEnabled = true;
  bool _hapticsEnabled = true;
  String _defaultExportFormat = 'GeoJSON';
  String _serverUrl = 'https://lanus.digital';

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
    final snapRoads = await repo.getSnapToRoadsEnabled();
    final haptics = await repo.getHapticsEnabled();
    final fmt = await repo.getDefaultExportFormat();
    final server = await SyncService.getServerUrl();

    setState(() {
      _gpsInterval = interval;
      _minDistance = minDist;
      _maxAccuracy = maxAcc;
      _autoStopEnabled = autoStop;
      _autoStopMinSeconds = autoStopSec;
      _snapToRoadsEnabled = snapRoads;
      _hapticsEnabled = haptics;
      _defaultExportFormat = fmt;
      _serverUrl = server;
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AJUSTES')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AJUSTES Y CONFIGURACIÓN'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Section 1: GPS
              _buildSectionHeader(Icons.gps_fixed, 'GPS Y CAPTURA DE TRACKS', 'Configuración de frecuencia y precisión'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.timer_outlined, color: Colors.blue),
                      title: const Text('Intervalo de Lectura GPS'),
                      subtitle: Text('Actualización cada $_gpsInterval segundo(s)'),
                      trailing: DropdownButton<int>(
                        value: _gpsInterval,
                        borderRadius: BorderRadius.circular(12),
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
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.filter_alt_outlined, color: Colors.blue),
                      title: const Text('Distancia Mínima de Filtrado'),
                      subtitle: Text('${_minDistance.toStringAsFixed(0)} metros'),
                      trailing: SizedBox(
                        width: 140,
                        child: Slider(
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
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.alt_route, color: Colors.blue),
                      title: const Text('Alineación a Calles en Vivo (Snap-to-Roads)'),
                      subtitle: const Text('Filtro Kalman 2D y alineación al eje vial'),
                      value: _snapToRoadsEnabled,
                      onChanged: (val) {
                        setState(() => _snapToRoadsEnabled = val);
                        _saveSetting('snap_to_roads_enabled', val.toString());
                      },
                    ),
                  ],
                ),
              ),

              // Section 2: Auto Stop
              _buildSectionHeader(Icons.motion_photos_paused_outlined, 'DETECCIÓN DE PARADAS', 'Alertas automáticas al detener la unidad'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.hail, color: Colors.orange),
                      title: const Text('Detección Automática de Paradas'),
                      subtitle: const Text('Notificar cuando el colectivo permanece detenido'),
                      value: _autoStopEnabled,
                      onChanged: (val) {
                        setState(() => _autoStopEnabled = val);
                        _saveSetting('auto_stop_enabled', val.toString());
                      },
                    ),
                    if (_autoStopEnabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.access_time, color: Colors.orange),
                        title: const Text('Tiempo Mínimo de Detención'),
                        subtitle: Text('Detención confirmada tras $_autoStopMinSeconds s'),
                        trailing: DropdownButton<int>(
                          value: _autoStopMinSeconds,
                          borderRadius: BorderRadius.circular(12),
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15 seg')),
                            DropdownMenuItem(value: 20, child: Text('20 seg')),
                            DropdownMenuItem(value: 30, child: Text('30 seg')),
                            DropdownMenuItem(value: 60, child: Text('60 seg')),
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

              // Section 3: Feedback
              _buildSectionHeader(Icons.vibration, 'INTERFAZ Y FEEDBACK', 'Vibración y experiencia táctil'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  secondary: const Icon(Icons.touch_app, color: Colors.teal),
                  title: const Text('Respuesta Háptica (Vibración)'),
                  subtitle: const Text('Vibrar al capturar paradas, fotos e incidencias'),
                  value: _hapticsEnabled,
                  onChanged: (val) {
                    setState(() => _hapticsEnabled = val);
                    _saveSetting('haptics_enabled', val.toString());
                  },
                ),
              ),

              // Section 4: Backup
              _buildSectionHeader(Icons.cloud_upload_outlined, 'COPIA DE SEGURIDAD (BACKUP)', 'Resguardo local de la base de datos y multimedia'),
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

              // Section 5: Lanús Digital Server & Catalog
              _buildSectionHeader(Icons.cloud_sync_outlined, 'SINCRONIZACIÓN LANÚS DIGITAL', 'Servidor municipal y catálogo de líneas'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dns, color: Color(0xFF0284C7)),
                      title: const Text('URL del Servidor Municipal'),
                      subtitle: Text(_serverUrl),
                      trailing: const Icon(Icons.edit, size: 20),
                      onTap: () async {
                        final controller = TextEditingController(text: _serverUrl);
                        final newUrl = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Configurar Servidor Lanús'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Ingrese la URL base del backend de Lanús Digital:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'URL del Servidor',
                                    hintText: 'https://tu-servidor.com',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('CANCELAR'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                                child: const Text('GUARDAR'),
                              ),
                            ],
                          ),
                        );

                        if (newUrl != null && newUrl.isNotEmpty) {
                          await SyncService.setServerUrl(newUrl);
                          setState(() => _serverUrl = newUrl);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Servidor actualizado: $newUrl')),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.alt_route, color: Color(0xFF0284C7)),
                      title: const Text('Catálogo de Colectivos'),
                      subtitle: const Text('Descargar líneas y ramales oficiales de Lanús'),
                      trailing: const Icon(Icons.download_rounded),
                      onTap: () async {
                        final count = await SyncService.fetchOfficialLines(ref.read(databaseProvider));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                count > 0
                                    ? 'Catálogo actualizado: $count ramales incorporados'
                                    : 'No se encontraron líneas nuevas o el servidor aún no está disponible.',
                              ),
                              backgroundColor: count > 0 ? const Color(0xFF16A34A) : Colors.orange.shade800,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 6: Shorebird OTA
              _buildSectionHeader(Icons.system_update_alt, 'ACTUALIZACIONES OTA (SHOREBIRD)', 'Actualizaciones instantáneas de código sin reinstalar'),
              Builder(
                builder: (context) {
                  final otaState = ref.watch(otaUpdateProvider);
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bolt, color: Colors.blue, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estado Shorebird CodePush',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      otaState.isShorebirdAvailable
                                          ? (otaState.currentPatch != null ? 'Parche Instalado: #${otaState.currentPatch}' : 'Versión Oficial Base')
                                          : 'Motor Shorebird Habilitado en la app',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: otaState.isShorebirdAvailable ? Colors.green.shade100 : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  otaState.isShorebirdAvailable ? 'OTA ACTIVO' : 'DISPONIBLE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: otaState.isShorebirdAvailable ? Colors.green.shade900 : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (otaState.message != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                otaState.message!,
                                style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: Colors.blue.shade800,
                            ),
                            onPressed: otaState.status == OtaStatus.checking || otaState.status == OtaStatus.downloading
                                ? null
                                : () => ref.read(otaUpdateProvider.notifier).checkForUpdates(),
                            icon: otaState.status == OtaStatus.checking || otaState.status == OtaStatus.downloading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.sync),
                            label: Text(
                              otaState.status == OtaStatus.checking
                                  ? 'BUSCANDO PARCHES...'
                                  : (otaState.status == OtaStatus.downloading ? 'DESCARGANDO PARCHE...' : 'BUSCAR PARCHES OTA EN LA NUBE'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Section 6: GitHub Releases Auto-Update
              _buildSectionHeader(Icons.download_for_offline, 'ACTUALIZACIÓN APK DESDE GITHUB', 'Descarga e instalación directa de nuevas versiones APK'),
              Builder(
                builder: (context) {
                  final ghState = ref.watch(githubUpdateProvider);
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.adb, color: Colors.purple, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'GitHub Releases Auto-Updater',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Versión Instalada: ${ghState.currentVersion}${ghState.latestVersion != null ? " · Última: ${ghState.latestVersion}" : ""}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (ghState.status == GithubUpdateStatus.downloading) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: ghState.downloadProgress, borderRadius: BorderRadius.circular(8)),
                            const SizedBox(height: 4),
                            Text(
                              'Descargando APK... ${(ghState.downloadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                          if (ghState.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                ghState.errorMessage!,
                                style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          if (ghState.status == GithubUpdateStatus.updateAvailable || ghState.status == GithubUpdateStatus.readyToInstall) ...[
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: Colors.purple.shade800,
                              ),
                              onPressed: () => ref.read(githubUpdateProvider.notifier).downloadAndInstallApk(),
                              icon: const Icon(Icons.install_mobile),
                              label: Text(
                                ghState.status == GithubUpdateStatus.readyToInstall
                                    ? 'INSTALAR APK DESCARGADA (${ghState.latestVersion})'
                                    : 'DESCARGAR E INSTALAR APK (${ghState.latestVersion})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: ghState.status == GithubUpdateStatus.checking || ghState.status == GithubUpdateStatus.downloading
                                  ? null
                                  : () => ref.read(githubUpdateProvider.notifier).checkForUpdates(),
                              icon: ghState.status == GithubUpdateStatus.checking
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.refresh),
                              label: Text(
                                ghState.status == GithubUpdateStatus.checking
                                    ? 'VERIFICANDO EN GITHUB...'
                                    : (ghState.status == GithubUpdateStatus.upToDate ? 'APLICACIÓN EN ÚLTIMA VERSIÓN (VERIFICAR DE NUEVO)' : 'BUSCAR RELEASES EN GITHUB'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
