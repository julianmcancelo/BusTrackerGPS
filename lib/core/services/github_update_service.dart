import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../constants/api_credentials.dart';

enum GithubUpdateStatus {
  idle,
  checking,
  updateAvailable,
  downloading,
  readyToInstall,
  upToDate,
  error,
}

class GithubUpdateState {
  final GithubUpdateStatus status;
  final String currentVersion;
  final String? latestVersion;
  final String? releaseNotes;
  final String? downloadUrl;
  final double downloadProgress;
  final String? downloadedFilePath;
  final String? errorMessage;

  const GithubUpdateState({
    this.status = GithubUpdateStatus.idle,
    this.currentVersion = 'v1.0.8',
    this.latestVersion,
    this.releaseNotes,
    this.downloadUrl,
    this.downloadProgress = 0.0,
    this.downloadedFilePath,
    this.errorMessage,
  });

  GithubUpdateState copyWith({
    GithubUpdateStatus? status,
    String? currentVersion,
    String? latestVersion,
    String? releaseNotes,
    String? downloadUrl,
    double? downloadProgress,
    String? downloadedFilePath,
    String? errorMessage,
  }) {
    return GithubUpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final githubUpdateProvider = NotifierProvider<GithubUpdateNotifier, GithubUpdateState>(GithubUpdateNotifier.new);

class GithubUpdateNotifier extends Notifier<GithubUpdateState> {
  @override
  GithubUpdateState build() {
    _initCurrentVersion();
    return const GithubUpdateState();
  }

  Future<void> _initCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = 'v${info.version}';
      state = state.copyWith(currentVersion: version);
    } catch (_) {}
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest.replaceAll('v', '').trim();
      final cleanCurrent = current.replaceAll('v', '').trim();

      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final r = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (_) {
      return latest != current;
    }
  }

  Future<void> checkForUpdates({bool autoDownload = false, BuildContext? context, bool showNoUpdateToast = false}) async {
    await _initCurrentVersion();
    state = state.copyWith(status: GithubUpdateStatus.checking, errorMessage: null);

    try {
      final response = await http.get(
        Uri.parse(LanusCredentials.githubReleasesApi),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestTag = (data['tag_name'] ?? '').toString();
        final bodyText = data['body']?.toString() ?? 'Actualización disponible de Lanús Digital.';
        final assets = data['assets'] as List<dynamic>? ?? [];

        String? apkDownloadUrl;
        for (final asset in assets) {
          final name = asset['name']?.toString().toLowerCase() ?? '';
          if (name.endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url']?.toString();
            break;
          }
        }
        apkDownloadUrl ??= LanusCredentials.directApkDownload;

        if (_isNewerVersion(latestTag, state.currentVersion)) {
          state = state.copyWith(
            status: GithubUpdateStatus.updateAvailable,
            latestVersion: latestTag,
            releaseNotes: bodyText,
            downloadUrl: apkDownloadUrl,
          );

          if (context != null && context.mounted) {
            _showUpdateDialog(context, latestTag, bodyText, apkDownloadUrl);
          } else if (autoDownload) {
            await downloadAndInstallApk();
          }
        } else {
          state = state.copyWith(
            status: GithubUpdateStatus.upToDate,
            latestVersion: latestTag,
            errorMessage: null,
          );
          if (showNoUpdateToast && context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ya tenés instalada la versión más reciente de Lanús Digital.')),
            );
          }
        }
      } else {
        state = state.copyWith(
          status: GithubUpdateStatus.error,
          errorMessage: 'No se pudo conectar a GitHub Releases (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: GithubUpdateStatus.error,
        errorMessage: 'Error al verificar versión en GitHub: $e',
      );
    }
  }

  void _showUpdateDialog(BuildContext context, String newVersion, String notes, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Text('Actualización: $newVersion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hay una nueva versión oficial de Lanús Digital lista para instalar.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(notes, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Más tarde'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Actualizar Ahora'),
            onPressed: () {
              Navigator.pop(ctx);
              downloadAndInstallApk(context: context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> downloadAndInstallApk({BuildContext? context}) async {
    final url = state.downloadUrl ?? LanusCredentials.directApkDownload;
    ScaffoldMessengerState? messenger;
    if (context != null && context.mounted) {
      messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 14),
              Text('Descargando actualización de Lanús Digital...'),
            ],
          ),
          duration: Duration(minutes: 3),
        ),
      );
    }

    state = state.copyWith(status: GithubUpdateStatus.downloading, downloadProgress: 0.0);

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/lanus_digital_${state.latestVersion ?? "update"}.apk';
      final file = File(filePath);

      final sink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (contentLength > 0) {
          final progress = (downloadedBytes / contentLength).clamp(0.0, 1.0);
          state = state.copyWith(downloadProgress: progress);
        }
      }

      await sink.close();

      state = state.copyWith(
        status: GithubUpdateStatus.readyToInstall,
        downloadedFilePath: filePath,
        downloadProgress: 1.0,
      );

      if (messenger != null) {
        messenger.hideCurrentSnackBar();
      }

      await installApk();
    } catch (e) {
      if (messenger != null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('Error al descargar la APK: $e')),
        );
      }
      state = state.copyWith(
        status: GithubUpdateStatus.error,
        errorMessage: 'Error al descargar la APK de GitHub: $e',
      );
    }
  }

  Future<void> installApk() async {
    final path = state.downloadedFilePath;
    if (path == null || !File(path).existsSync()) {
      state = state.copyWith(
        status: GithubUpdateStatus.error,
        errorMessage: 'Archivo APK no encontrado para instalación',
      );
      return;
    }

    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        state = state.copyWith(
          status: GithubUpdateStatus.error,
          errorMessage: 'Resultado de instalación: ${result.message}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: GithubUpdateStatus.error,
        errorMessage: 'Error al abrir el instalador APK: $e',
      );
    }
  }
}

class GitHubUpdateService {
  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateToast = false}) async {
    try {
      final container = ProviderScope.containerOf(context);
      await container.read(githubUpdateProvider.notifier).checkForUpdates(
        context: context,
        showNoUpdateToast: showNoUpdateToast,
      );
    } catch (_) {}
  }
}
