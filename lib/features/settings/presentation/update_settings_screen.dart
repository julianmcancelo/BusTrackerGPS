import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/ota_update_service.dart';
import '../../../core/services/github_update_service.dart';

class UpdateSettingsScreen extends ConsumerWidget {
  const UpdateSettingsScreen({super.key});

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title, String subtitle) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizaciones del Sistema')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section: OTA Shorebird
              _buildSectionHeader(context, Icons.bolt, 'ACTUALIZACIONES SILENCIOSAS OTA', 'Motor de parches Shorebird en segundo plano'),
              Builder(
                builder: (context) {
                  final otaState = ref.watch(otaUpdateProvider);
                  final isAvail = otaState.isShorebirdAvailable;
                  final hasPatch = otaState.currentPatch != null;
                  final isError = otaState.status == OtaStatus.error;
                  final isRestart = otaState.status == OtaStatus.readyToRestart;
                  final isWorking = otaState.status == OtaStatus.checking || otaState.status == OtaStatus.downloading;

                  final statusColor = !isAvail
                      ? Colors.grey
                      : isError
                          ? Colors.red
                          : isRestart
                              ? Colors.amber.shade800
                              : const Color(0xFF059669);

                  final badgeText = !isAvail
                      ? 'CANAL GITHUB'
                      : hasPatch
                          ? 'PARCHE #${otaState.currentPatch} ACTIVO'
                          : 'OFICIAL ${otaState.releaseVersion}';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Engine & Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.bolt, color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Shorebird Code Push Engine',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAvail
                                          ? 'Motor en línea · Canal ${otaState.track}'
                                          : 'Actualización automática vía GitHub Releases',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      badgeText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          // Telemetry Metrics Grid
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                _buildOtaMetricTile('CANAL', otaState.track.toUpperCase(), Icons.alt_route),
                                _buildVerticalDivider(),
                                _buildOtaMetricTile('BASE', otaState.releaseVersion, Icons.layers_outlined),
                                _buildVerticalDivider(),
                                _buildOtaMetricTile('PARCHE', hasPatch ? '#${otaState.currentPatch}' : 'Oficial', Icons.verified_outlined),
                                _buildVerticalDivider(),
                                _buildOtaMetricTile(
                                  'CHEQUEO',
                                  otaState.lastCheckedAt != null
                                      ? DateFormat('HH:mm').format(otaState.lastCheckedAt!)
                                      : 'Pendiente',
                                  Icons.access_time,
                                ),
                              ],
                            ),
                          ),

                          // Active Progress Tracker
                          if (isWorking) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: Colors.blue.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                              ),
                            ),
                          ],

                          // Status Message Banner
                          if (otaState.message != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isError
                                        ? Colors.red
                                        : isRestart
                                            ? Colors.amber
                                            : Colors.blue)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (isError
                                          ? Colors.red
                                          : isRestart
                                              ? Colors.amber
                                              : Colors.blue)
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isError
                                        ? Icons.error_outline
                                        : isRestart
                                            ? Icons.restart_alt
                                            : Icons.check_circle_outline,
                                    size: 16,
                                    color: isError
                                        ? Colors.red.shade800
                                        : isRestart
                                            ? Colors.amber.shade900
                                            : Colors.blue.shade800,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      otaState.message!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isError
                                            ? Colors.red.shade900
                                            : isRestart
                                                ? Colors.amber.shade900
                                                : Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),
                          // Action Buttons
                          if (isRestart)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: Colors.amber.shade800,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor, cierra y vuelve a abrir la app para activar el nuevo parche'),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.restart_alt, size: 20),
                              label: const Text(
                                'PARCHE INSTALADO · REINICIAR APP',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            )
                          else
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: const Color(0xFF0284C7),
                              ),
                              onPressed: isWorking
                                  ? null
                                  : () => ref.read(otaUpdateProvider.notifier).checkForUpdates(),
                              icon: isWorking
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.sync, size: 20),
                              label: Text(
                                otaState.status == OtaStatus.checking
                                    ? 'VERIFICANDO PARCHES...'
                                    : (otaState.status == OtaStatus.downloading
                                        ? 'DESCARGANDO PARCHE EN SEGUNDO PLANO...'
                                        : 'BUSCAR Y APLICAR PARCHES SILENCIOSOS'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),

                          const SizedBox(height: 10),
                          // Collapsible/Static Explainer
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Shorebird descarga correcciones y mejoras directamente en la memoria del dispositivo, sin necesidad de descargar un APK nuevo ni reinstalar la aplicación.',
                                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Section: GitHub Releases Auto-Update
              _buildSectionHeader(context, Icons.download_for_offline, 'ACTUALIZACIÓN APK DESDE GITHUB', 'Descarga e instalación directa de nuevas versiones APK'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtaMetricTile(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 3),
              Text(
                title,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
