import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/database.dart';
import '../../../database/database_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

class SettingsRepository {
  final AppDatabase db;
  SettingsRepository(this.db);

  Future<String?> getSetting(String key) async {
    final entry = await (db.select(db.settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return entry?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: key,
            value: value,
          ),
        );
  }

  Future<int> getGpsIntervalSeconds() async {
    final v = await getSetting('gps_interval_seconds');
    return int.tryParse(v ?? '') ?? 2;
  }

  Future<double> getGpsMinDistance() async {
    final v = await getSetting('gps_min_distance');
    return double.tryParse(v ?? '') ?? 3.0;
  }

  Future<double> getGpsMaxAccuracy() async {
    final v = await getSetting('gps_max_accuracy');
    return double.tryParse(v ?? '') ?? 50.0;
  }

  Future<bool> getAutoStopEnabled() async {
    final v = await getSetting('auto_stop_enabled');
    return v == null ? true : v == 'true';
  }

  Future<int> getAutoStopMinSeconds() async {
    final v = await getSetting('auto_stop_min_seconds');
    return int.tryParse(v ?? '') ?? 20;
  }

  Future<double> getAutoStopMaxSpeedKmh() async {
    final v = await getSetting('auto_stop_max_speed_kmh');
    return double.tryParse(v ?? '') ?? 2.0;
  }

  Future<bool> getHapticsEnabled() async {
    final v = await getSetting('haptics_enabled');
    return v == null ? true : v == 'true';
  }

  Future<String> getDefaultExportFormat() async {
    final v = await getSetting('default_export_format');
    return v ?? 'GeoJSON';
  }

  Future<bool> getSnapToRoadsEnabled() async {
    final v = await getSetting('snap_to_roads_enabled');
    return v == null ? true : v == 'true';
  }

  Future<double> getDeviationThresholdMeters() async {
    final v = await getSetting('deviation_threshold_meters');
    return double.tryParse(v ?? '') ?? 100.0;
  }
}

