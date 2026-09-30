import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

const String githubReleasesApiUrl = 'https://api.github.com/repos/julianmcancelo/BusTrackerGPS/releases/latest';

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

      final latestParts = cleanLatest.split('.').map(int.parse).toList();
      final currentParts = cleanCurrent.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return latest != current;
    }
  }

  Future<void> checkForUpdates({bool autoDownload = false}) async {
    await _initCurrentVersion();
    state = state.copyWith(status: GithubUpdateStatus.checking, errorMessage: null);

    try {
      final response = await http.get(
        Uri.parse(githubReleasesApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestTag = data['tag_name']?.toString() ?? '';
        final bodyText = data['body']?.toString() ?? '';
        final assets = data['assets'] as List<dynamic>? ?? [];

        String? apkDownloadUrl;
        for (final asset in assets) {
          final name = asset['name']?.toString().toLowerCase() ?? '';
          if (name.endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url']?.toString();
            break;
          }
        }

        if (_isNewerVersion(latestTag, state.currentVersion)) {
          state = state.copyWith(
            status: GithubUpdateStatus.updateAvailable,
            latestVersion: latestTag,
            releaseNotes: bodyText,
            downloadUrl: apkDownloadUrl,
          );

          if (autoDownload && apkDownloadUrl != null) {
            await downloadAndInstallApk();
          }
        } else {
          state = state.copyWith(
            status: GithubUpdateStatus.upToDate,
            latestVersion: latestTag,
            errorMessage: null,
          );
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

  Future<void> downloadAndInstallApk() async {
    final url = state.downloadUrl;
    if (url == null || url.isEmpty) {
      state = state.copyWith(
        status: GithubUpdateStatus.error,
        errorMessage: 'No se encontró enlace de descarga APK en la release',
      );
      return;
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

      await installApk();
    } catch (e) {
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
