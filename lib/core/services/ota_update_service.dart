import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

enum OtaStatus {
  unavailable,
  idle,
  checking,
  downloading,
  updateAvailable,
  readyToRestart,
  error,
}

class OtaState {
  final OtaStatus status;
  final int? currentPatch;
  final String? message;
  final bool isShorebirdAvailable;
  final DateTime? lastCheckedAt;
  final String releaseVersion;
  final String track;

  const OtaState({
    this.status = OtaStatus.idle,
    this.currentPatch,
    this.message,
    this.isShorebirdAvailable = false,
    this.lastCheckedAt,
    this.releaseVersion = '1.0.19+19',
    this.track = 'stable',
  });

  OtaState copyWith({
    OtaStatus? status,
    int? currentPatch,
    String? message,
    bool? isShorebirdAvailable,
    DateTime? lastCheckedAt,
    String? releaseVersion,
    String? track,
  }) {
    return OtaState(
      status: status ?? this.status,
      currentPatch: currentPatch ?? this.currentPatch,
      message: message ?? this.message,
      isShorebirdAvailable: isShorebirdAvailable ?? this.isShorebirdAvailable,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      releaseVersion: releaseVersion ?? this.releaseVersion,
      track: track ?? this.track,
    );
  }
}

final otaUpdateProvider = NotifierProvider<OtaUpdateNotifier, OtaState>(OtaUpdateNotifier.new);

class OtaUpdateNotifier extends Notifier<OtaState> {
  final ShorebirdUpdater _shorebird = ShorebirdUpdater();

  @override
  OtaState build() {
    final available = _shorebird.isAvailable;
    state = OtaState(
      status: available ? OtaStatus.idle : OtaStatus.unavailable,
      isShorebirdAvailable: available,
    );
    if (available) {
      _loadCurrentPatch();
    }
    return state;
  }

  Future<void> _loadCurrentPatch() async {
    try {
      final patch = await _shorebird.readCurrentPatch();
      state = state.copyWith(currentPatch: patch?.number);
    } catch (_) {}
  }

  Future<void> checkForUpdates({bool autoDownload = true}) async {
    if (!state.isShorebirdAvailable) {
      state = state.copyWith(
        status: OtaStatus.unavailable,
        message: 'Shorebird OTA opera en segundo plano en el APK instalado en Android (ARM64). En PC o emulador use la actualización de GitHub.',
      );
      return;
    }

    state = state.copyWith(
      status: OtaStatus.checking,
      message: 'Consultando servidores de Shorebird...',
      lastCheckedAt: DateTime.now(),
    );

    try {
      final updateTrack = await _shorebird.checkForUpdate();

      if (updateTrack == UpdateStatus.outdated) {
        if (autoDownload) {
          await downloadUpdate();
        } else {
          state = state.copyWith(
            status: OtaStatus.updateAvailable,
            message: 'Nuevo parche OTA detectado en la nube. Listo para instalar.',
            lastCheckedAt: DateTime.now(),
          );
        }
      } else {
        final patch = await _shorebird.readCurrentPatch();
        state = state.copyWith(
          status: OtaStatus.idle,
          currentPatch: patch?.number,
          message: patch != null
              ? 'Aplicación al día con el Parche #${patch.number} activo y operativo.'
              : 'Aplicación conectada a la versión oficial base 1.0.19+19. El motor OTA está en línea y esperando nuevos parches.',
          lastCheckedAt: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: OtaStatus.error,
        message: 'No se pudo conectar con el servidor de parches: $e',
        lastCheckedAt: DateTime.now(),
      );
    }
  }

  Future<void> downloadUpdate() async {
    if (!state.isShorebirdAvailable) return;

    state = state.copyWith(
      status: OtaStatus.downloading,
      message: 'Descargando parche OTA en segundo plano...',
      lastCheckedAt: DateTime.now(),
    );

    try {
      await _shorebird.update();
      final patch = await _shorebird.readCurrentPatch();
      state = state.copyWith(
        status: OtaStatus.readyToRestart,
        currentPatch: patch?.number,
        message: '¡Parche #${patch?.number ?? 1} descargado e instalado con éxito! Reinicie la aplicación para activarlo.',
        lastCheckedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: OtaStatus.error,
        message: 'Error al descargar el parche: $e',
        lastCheckedAt: DateTime.now(),
      );
    }
  }
}
