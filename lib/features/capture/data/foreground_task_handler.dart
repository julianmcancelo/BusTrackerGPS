import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import '../../../database/database.dart';
import 'gps_repository.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BitacoraGpsTaskHandler());
}

class BitacoraGpsTaskHandler extends TaskHandler {
  AppDatabase? _db;
  GpsRepository? _gpsRepo;
  StreamSubscription<Position>? _positionSub;
  String? _tripId;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _db = AppDatabase();
    _gpsRepo = GpsRepository(_db!);

    // Subscribe to Geolocator position stream
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
      intervalDuration: const Duration(seconds: 2),
      forceLocationManager: false,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) async {
      if (_tripId != null && _gpsRepo != null) {
        try {
          await _gpsRepo!.insertTrackPoint(
            tripId: _tripId!,
            position: position,
            maxAccuracyThreshold: 50.0,
          );
        } catch (_) {}
      }
    });
  }

  @override
  Future<void> onReceiveData(Object data) async {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('tripId')) {
        _tripId = data['tripId'] as String?;
      }
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Notification update on repeat interval
    if (_tripId != null) {
      FlutterForegroundTask.updateService(
        notificationTitle: '🚍 Bitácora GPS',
        notificationText: 'Captura activa en segundo plano...',
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSub?.cancel();
    await _db?.close();
  }
}
