import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              _buildSectionHeader(context, Icons.system_update_alt, 'ACTUALIZACIONES OTA', 'Parches silenciosos al motor interno'),
              Builder(
                builder: (context) {
                  final otaState = ref.watch(otaUpdateProvider);
                  final isAvail = otaState.isShorebirdAvailable;
                  final hasPatch = otaState.currentPatch != null;
                  final isError = otaState.status == OtaStatus.error;
                  final isRestart = otaState.status == OtaStatus.readyToRestart;

                  final statusColor = !isAvail
                      ? Colors.grey
                      : isError
                          ? Colors.red
                          : isRestart
                              ? Colors.amber.shade800
                              : const Color(0xFF059669);

                  final badgeText = !isAvail
                      ? 'MODO DEV / EMULADOR'
                      : hasPatch
                          ? 'PARCHE #${otaState.currentPatch} ACTIVO'
                          : 'VERSIÓN OFICIAL 1.0.19+19';

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
                                  color: statusColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.cloud_sync_outlined, color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Motor de Parches Shorebird OTA',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAvail
                                          ? 'Canal activo: Listo para recibir mejoras sin reinstalar APK'
                                          : 'Inactivo en emulador (activo en APK instalado en celular)',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                            : Icons.info_outline,
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
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: const Color(0xFF0284C7),
                            ),
                            onPressed: otaState.status == OtaStatus.checking || otaState.status == OtaStatus.downloading
                                ? null
                                : () => ref.read(otaUpdateProvider.notifier).checkForUpdates(),
                            icon: otaState.status == OtaStatus.checking || otaState.status == OtaStatus.downloading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.sync, size: 20),
                            label: Text(
                              otaState.status == OtaStatus.checking
                                  ? 'BUSCANDO PARCHES...'
                                  : (otaState.status == OtaStatus.downloading ? 'DESCARGANDO PARCHE...' : 'BUSCAR PARCHES OTA EN LA NUBE'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
}
