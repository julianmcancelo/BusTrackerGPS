import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../database/database.dart';
import '../domain/capture_state.dart';
import '../data/gps_repository.dart';
import '../data/foreground_task_handler.dart';
import '../../trips/data/trips_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/utils/haptics_utils.dart';
import '../../../core/permissions/permissions_handler.dart';

final captureNotifierProvider = NotifierProvider<CaptureNotifier, CaptureState>(CaptureNotifier.new);

class CaptureNotifier extends Notifier<CaptureState> {
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<Position>? _idleLocationSub;
  Timer? _timer;
  DateTime? _stoppedSince;

  TripsRepository get tripsRepo => ref.read(tripsRepositoryProvider);
  GpsRepository get gpsRepo => ref.read(gpsRepositoryProvider);
  SettingsRepository get settingsRepo => ref.read(settingsRepositoryProvider);

  @override
  CaptureState build() {
    ref.onDispose(() {
      _positionSub?.cancel();
      _idleLocationSub?.cancel();
      _timer?.cancel();
    });
    checkActiveTripRecovery();
    _startIdleLocationStream();
    return const CaptureState();
  }

  Future<void> _startIdleLocationStream() async {
    try {
      final hasPerms = await AppPermissionsHandler.checkAndRequestLocationPermissions();
      if (!hasPerms) return;

      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      state = state.copyWith(currentPosition: initialPos);

      _idleLocationSub = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 1),
          forceLocationManager: true,
        ),
      ).listen((pos) {
        if (state.status == CaptureStatus.idle) {
          state = state.copyWith(
            currentPosition: pos,
            gpsSignalQuality: pos.accuracy <= 15 ? 'EXCELLENT' : (pos.accuracy <= 30 ? 'GOOD' : 'LOW'),
          );
        }
      });
    } catch (_) {}
  }

  Future<void> checkActiveTripRecovery() async {
    try {
      final activeTrip = await tripsRepo.getActiveTrip();
      if (activeTrip != null) {
        final details = await tripsRepo.getTripWithDetails(activeTrip.id);
        if (details != null) {
          final points = await gpsRepo.getTrackPoints(activeTrip.id);
          final stops = await gpsRepo.getStops(activeTrip.id);
          final incidents = await gpsRepo.getIncidents(activeTrip.id);

          Position? lastPos;
          if (points.isNotEmpty) {
            final lastP = points.last;
            lastPos = Position(
              latitude: lastP.latitude,
              longitude: lastP.longitude,
              timestamp: lastP.timestamp,
              accuracy: lastP.accuracy ?? 0.0,
              altitude: lastP.altitude ?? 0.0,
              altitudeAccuracy: 0.0,
              heading: lastP.bearingDegrees ?? 0.0,
              headingAccuracy: 0.0,
              speed: lastP.speedMps ?? 0.0,
              speedAccuracy: 0.0,
            );
          }

          state = state.copyWith(
            status: activeTrip.status == 'PAUSED' ? CaptureStatus.paused : CaptureStatus.active,
            tripId: activeTrip.id,
            line: details.line,
            branch: details.branch,
            direction: activeTrip.direction,
            internalNumber: activeTrip.internalNumber,
            domain: activeTrip.domain,
            driverName: activeTrip.driverName,
            pointCount: points.length,
            stopCount: stops.length,
            incidentCount: incidents.length,
            totalDistanceMeters: activeTrip.distanceMeters,
            elapsedSeconds: (activeTrip.durationMs / 1000).round(),
            movingTimeSeconds: (activeTrip.movingTimeMs / 1000).round(),
            stoppedTimeSeconds: (activeTrip.stoppedTimeMs / 1000).round(),
            avgSpeedKmh: activeTrip.averageSpeedKmh,
            maxSpeedKmh: activeTrip.maxSpeedKmh,
            lastAcceptedPosition: lastPos,
            currentPosition: lastPos ?? state.currentPosition,
          );

          if (activeTrip.status == 'ACTIVE') {
            _startTrackingStreams(activeTrip.id);
          }
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> startCapture({
    required LineEntry line,
    required BranchEntry branch,
    required String direction,
    String? internalNumber,
    String? domain,
    String? driverName,
    String? notes,
  }) async {
    state = state.copyWith(status: CaptureStatus.starting);
    try {
      final tripId = await tripsRepo.createTrip(
        lineId: line.id,
        branchId: branch.id,
        direction: direction,
        internalNumber: internalNumber,
        domain: domain,
        driverName: driverName,
        notes: notes,
      );

      state = state.copyWith(
        status: CaptureStatus.active,
        tripId: tripId,
        line: line,
        branch: branch,
        direction: direction,
        internalNumber: internalNumber,
        domain: domain,
        driverName: driverName,
        pointCount: 0,
        stopCount: 0,
        incidentCount: 0,
        totalDistanceMeters: 0.0,
        elapsedSeconds: 0,
        movingTimeSeconds: 0,
        stoppedTimeSeconds: 0,
        currentSpeedKmh: 0.0,
        avgSpeedKmh: 0.0,
        maxSpeedKmh: 0.0,
      );

      await _startForegroundService();
      await _startTrackingStreams(tripId);

      final haptics = await settingsRepo.getHapticsEnabled();
      HapticsUtils.vibrateSuccess(enabled: haptics);
    } catch (e) {
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: 'Error al iniciar captura: $e',
      );
    }
  }

  Future<void> _startForegroundService() async {
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'bitacora_gps_channel',
          channelName: 'Bitácora GPS Tracking',
          channelDescription: 'Seguimiento GPS de colectivo en segundo plano',
          channelImportance: NotificationChannelImportance.HIGH,
          priority: NotificationPriority.HIGH,
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(5000),
          autoRunOnBoot: false,
          allowWakeLock: true,
        ),
      );

      await FlutterForegroundTask.startService(
        notificationTitle: 'NSE Bitácora GPS',
        notificationText: '${state.line?.number ?? ''} · ${state.branch?.name ?? ''} · ${state.direction}',
        callback: startCallback,
      );

      FlutterForegroundTask.sendDataToTask({'tripId': state.tripId});
    } catch (_) {}
  }

  Future<void> _startTrackingStreams(String tripId) async {
    await _positionSub?.cancel();
    await _idleLocationSub?.cancel();
    _timer?.cancel();

    final maxAccuracy = await settingsRepo.getGpsMaxAccuracy();
    final autoStopEnabled = await settingsRepo.getAutoStopEnabled();
    final autoStopMinSec = await settingsRepo.getAutoStopMinSeconds();
    final autoStopMaxSpeed = await settingsRepo.getAutoStopMaxSpeedKmh();

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
      forceLocationManager: true,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position pos) => _handleNewPosition(pos, maxAccuracy, autoStopEnabled, autoStopMinSec, autoStopMaxSpeed));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == CaptureStatus.active) {
        final elapsed = state.elapsedSeconds + 1;
        bool isMoving = state.currentSpeedKmh > autoStopMaxSpeed;

        int mSeconds = state.movingTimeSeconds + (isMoving ? 1 : 0);
        int sSeconds = state.stoppedTimeSeconds + (!isMoving ? 1 : 0);

        final avgSpeed = elapsed > 0 ? (state.totalDistanceMeters / elapsed) * 3.6 : 0.0;

        bool posStop = state.possibleStopDetected;
        int posStopSec = state.possibleStopSeconds;

        if (autoStopEnabled) {
          if (!isMoving) {
            _stoppedSince ??= DateTime.now();
            posStopSec = DateTime.now().difference(_stoppedSince!).inSeconds;
            if (posStopSec >= autoStopMinSec) {
              posStop = true;
            }
          } else {
            _stoppedSince = null;
            posStop = false;
            posStopSec = 0;
          }
        }

        state = state.copyWith(
          elapsedSeconds: elapsed,
          movingTimeSeconds: mSeconds,
          stoppedTimeSeconds: sSeconds,
          avgSpeedKmh: avgSpeed,
          possibleStopDetected: posStop,
          possibleStopSeconds: posStopSec,
        );

        final distKm = (state.totalDistanceMeters / 1000.0).toStringAsFixed(2);
        final timeStr = GeoUtils.formatDuration(Duration(seconds: elapsed));
        FlutterForegroundTask.updateService(
          notificationTitle: '🚍 Bitácora GPS - ${state.line?.number ?? ''}',
          notificationText: 'Capturando · $distKm km · $timeStr',
        );
      }
    });
  }

  Future<void> _handleNewPosition(
    Position pos,
    double maxAccuracy,
    bool autoStopEnabled,
    int autoStopMinSec,
    double autoStopMaxSpeed,
  ) async {
    if (state.tripId == null || state.status != CaptureStatus.active) return;

    final lastAccepted = state.lastAcceptedPosition;
    final DateTime now = pos.timestamp;

    final pointEntry = await gpsRepo.insertTrackPoint(
      tripId: state.tripId!,
      position: pos,
      maxAccuracyThreshold: maxAccuracy,
      lastPosition: lastAccepted,
      lastPositionTime: lastAccepted?.timestamp,
    );

    String signal = 'EXCELLENT';
    if (pos.accuracy > 30) {
      signal = 'LOW';
    } else if (pos.accuracy > 15) {
      signal = 'GOOD';
    }

    double newDist = state.totalDistanceMeters;
    Position? updatedLastAccepted = lastAccepted;
    double currentSpeed = (pos.speed * 3.6).clamp(0.0, 180.0);
    double maxSpeed = state.maxSpeedKmh;

    if (pointEntry.quality != 'OUTLIER') {
      if (lastAccepted != null) {
        final stepDist = GeoUtils.distanceMeters(
          lastAccepted.latitude,
          lastAccepted.longitude,
          pos.latitude,
          pos.longitude,
        );
        newDist += stepDist;
      }
      updatedLastAccepted = pos;
      if (currentSpeed > maxSpeed) {
        maxSpeed = currentSpeed;
      }
    }

    state = state.copyWith(
      currentPosition: pos,
      lastAcceptedPosition: updatedLastAccepted,
      pointCount: state.pointCount + 1,
      totalDistanceMeters: newDist,
      currentSpeedKmh: currentSpeed,
      maxSpeedKmh: maxSpeed,
      gpsSignalQuality: signal,
      lastGpsUpdate: now,
    );

    if (state.pointCount % 5 == 0) {
      tripsRepo.updateTripStats(
        tripId: state.tripId!,
        durationMs: state.elapsedSeconds * 1000,
        distanceMeters: state.totalDistanceMeters,
        movingTimeMs: state.movingTimeSeconds * 1000,
        stoppedTimeMs: state.stoppedTimeSeconds * 1000,
        averageSpeedKmh: state.avgSpeedKmh,
        maxSpeedKmh: state.maxSpeedKmh,
        pointCount: state.pointCount,
        stopCount: state.stopCount,
        incidentCount: state.incidentCount,
      );
    }
  }

  Future<void> pauseCapture() async {
    if (state.tripId == null) return;
    state = state.copyWith(status: CaptureStatus.paused);
    await tripsRepo.updateTripStatus(state.tripId!, 'PAUSED');
    final haptics = await settingsRepo.getHapticsEnabled();
    HapticsUtils.vibrateShort(enabled: haptics);
  }

  Future<void> resumeCapture() async {
    if (state.tripId == null) return;
    state = state.copyWith(status: CaptureStatus.active);
    await tripsRepo.updateTripStatus(state.tripId!, 'ACTIVE');
    final haptics = await settingsRepo.getHapticsEnabled();
    HapticsUtils.vibrateShort(enabled: haptics);
  }

  Future<void> addManualStop({String? name, String? notes}) async {
    final pos = state.currentPosition;
    if (state.tripId == null || pos == null) return;

    await gpsRepo.insertStop(
      tripId: state.tripId!,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      name: name,
      notes: notes,
      status: 'MANUAL',
    );

    state = state.copyWith(
      stopCount: state.stopCount + 1,
      possibleStopDetected: false,
      possibleStopSeconds: 0,
    );
    _stoppedSince = null;

    final haptics = await settingsRepo.getHapticsEnabled();
    HapticsUtils.vibrateSuccess(enabled: haptics);
  }

  Future<void> confirmAutoStop() async {
    final pos = state.currentPosition;
    if (state.tripId == null || pos == null) return;

    await gpsRepo.insertStop(
      tripId: state.tripId!,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      status: 'CONFIRMED',
      dwellTimeMs: state.possibleStopSeconds * 1000,
    );

    state = state.copyWith(
      stopCount: state.stopCount + 1,
      possibleStopDetected: false,
      possibleStopSeconds: 0,
    );
    _stoppedSince = null;

    final haptics = await settingsRepo.getHapticsEnabled();
    HapticsUtils.vibrateSuccess(enabled: haptics);
  }

  void ignoreAutoStop() {
    state = state.copyWith(
      possibleStopDetected: false,
      possibleStopSeconds: 0,
    );
    _stoppedSince = null;
  }

  Future<void> addIncident({
    required String type,
    String severity = 'LOW',
    String? description,
  }) async {
    final pos = state.currentPosition;
    if (state.tripId == null || pos == null) return;

    await gpsRepo.insertIncident(
      tripId: state.tripId!,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      type: type,
      severity: severity,
      description: description,
    );

    state = state.copyWith(incidentCount: state.incidentCount + 1);

    final haptics = await settingsRepo.getHapticsEnabled();
    HapticsUtils.vibrateSuccess(enabled: haptics);
  }

  Future<void> addPhoto(String filePath, {String? notes}) async {
    final pos = state.currentPosition;
    if (state.tripId == null) return;

    await gpsRepo.insertAttachment(
      tripId: state.tripId!,
      type: 'PHOTO',
      filePath: filePath,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      notes: notes,
    );

    final haptics = await settingsRepo.getHapticsEnabled();
    HapticsUtils.vibrateShort(enabled: haptics);
  }

  Future<void> addAudio(String filePath, {String? notes}) async {
    final pos = state.currentPosition;
    if (state.tripId == null) return;

    await gpsRepo.insertAttachment(
      tripId: state.tripId!,
      type: 'AUDIO',
      filePath: filePath,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      notes: notes,
    );

    final haptics = await settingsRepo.getHapticsEnabled();
    HapticsUtils.vibrateShort(enabled: haptics);
  }

  Future<String?> finishCapture() async {
    final tripId = state.tripId;
    if (tripId == null) return null;

    state = state.copyWith(status: CaptureStatus.stopping);

    await _positionSub?.cancel();
    _timer?.cancel();

    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}

    await tripsRepo.finishTrip(
      tripId: tripId,
      durationMs: state.elapsedSeconds * 1000,
      distanceMeters: state.totalDistanceMeters,
      movingTimeMs: state.movingTimeSeconds * 1000,
      stoppedTimeMs: state.stoppedTimeSeconds * 1000,
      averageSpeedKmh: state.avgSpeedKmh,
      maxSpeedKmh: state.maxSpeedKmh,
      pointCount: state.pointCount,
      stopCount: state.stopCount,
      incidentCount: state.incidentCount,
    );

    final finishedTripId = state.tripId;

    state = const CaptureState(status: CaptureStatus.idle);
    _startIdleLocationStream();

    final haptics = await settingsRepo.getHapticsEnabled();
    HapticsUtils.vibrateSuccess(enabled: haptics);

    return finishedTripId;
  }
}
