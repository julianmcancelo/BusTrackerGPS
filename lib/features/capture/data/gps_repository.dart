import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../database/database.dart';
import '../../../database/database_provider.dart';
import '../../../core/utils/geo_utils.dart';

final gpsRepositoryProvider = Provider<GpsRepository>((ref) {
  return GpsRepository(ref.watch(databaseProvider));
});

class GpsRepository {
  final AppDatabase db;
  GpsRepository(this.db);

  Future<TrackPointEntry> insertTrackPoint({
    required String tripId,
    required Position position,
    required double maxAccuracyThreshold,
    Position? lastPosition,
    DateTime? lastPositionTime,
  }) async {
    String quality = 'GOOD';
    bool isAccepted = true;

    // Check accuracy quality
    if (position.accuracy > maxAccuracyThreshold) {
      quality = 'LOW_ACCURACY';
    }

    // Check outlier condition relative to previous point
    if (lastPosition != null && lastPositionTime != null) {
      final isOutlierPoint = GeoUtils.isOutlier(
        lastLat: lastPosition.latitude,
        lastLon: lastPosition.longitude,
        lastTime: lastPositionTime,
        newLat: position.latitude,
        newLon: position.longitude,
        newTime: position.timestamp,
      );

      if (isOutlierPoint) {
        quality = 'OUTLIER';
        isAccepted = false;
      }
    }

    final id = await db.into(db.trackPoints).insert(
          TrackPointsCompanion.insert(
            tripId: tripId,
            timestamp: Value(position.timestamp),
            elapsedRealtimeNanos: Value(position.timestamp.millisecondsSinceEpoch * 1000000),
            latitude: position.latitude,
            longitude: position.longitude,
            altitude: Value(position.altitude),
            accuracy: Value(position.accuracy),
            speedMps: Value(position.speed),
            bearingDegrees: Value(position.heading),
            provider: const Value('gps'),
            quality: Value(quality),
            isAccepted: Value(isAccepted),
          ),
        );

    return (await (db.select(db.trackPoints)..where((t) => t.id.equals(id))).getSingle());
  }

  Future<int> insertStop({
    required String tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
    String? name,
    String? code,
    String status = 'MANUAL',
    String? notes,
    int? dwellTimeMs,
    DateTime? arrivalAt,
    DateTime? departureAt,
  }) async {
    final count = await (db.select(db.stops)..where((t) => t.tripId.equals(tripId))).get();
    final sequence = count.length + 1;
    final now = DateTime.now();

    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tripId: tripId,
            sequence: Value(sequence),
            latitude: latitude,
            longitude: longitude,
            accuracy: Value(accuracy),
            markedAt: Value(now),
            arrivalAt: Value(arrivalAt ?? now),
            departureAt: Value(departureAt),
            dwellTimeMs: Value(dwellTimeMs),
            name: Value(name),
            code: Value(code),
            status: Value(status),
            notes: Value(notes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return id;
  }

  Future<int> insertIncident({
    required String tripId,
    required double latitude,
    required double longitude,
    double? accuracy,
    required String type,
    String severity = 'LOW',
    String? description,
  }) async {
    final now = DateTime.now();
    final id = await db.into(db.incidents).insert(
          IncidentsCompanion.insert(
            tripId: tripId,
            timestamp: Value(now),
            latitude: latitude,
            longitude: longitude,
            accuracy: Value(accuracy),
            type: type,
            severity: Value(severity),
            description: Value(description),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return id;
  }

  Future<int> insertAttachment({
    required String tripId,
    int? stopId,
    int? incidentId,
    required String type, // PHOTO, AUDIO, FILE
    required String filePath,
    double? latitude,
    double? longitude,
    int? fileSizeBytes,
    String? notes,
  }) async {
    final now = DateTime.now();
    final id = await db.into(db.attachments).insert(
          AttachmentsCompanion.insert(
            tripId: tripId,
            stopId: Value(stopId),
            incidentId: Value(incidentId),
            type: type,
            filePath: filePath,
            timestamp: Value(now),
            latitude: Value(latitude),
            longitude: Value(longitude),
            fileSizeBytes: Value(fileSizeBytes),
            notes: Value(notes),
            createdAt: Value(now),
          ),
        );

    return id;
  }

  Future<List<TrackPointEntry>> getTrackPoints(String tripId) {
    return (db.select(db.trackPoints)
          ..where((t) => t.tripId.equals(tripId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<List<StopEntry>> getStops(String tripId) {
    return (db.select(db.stops)
          ..where((t) => t.tripId.equals(tripId))
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
        .get();
  }

  Future<List<IncidentEntry>> getIncidents(String tripId) {
    return (db.select(db.incidents)
          ..where((t) => t.tripId.equals(tripId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<List<AttachmentEntry>> getAttachments(String tripId) {
    return (db.select(db.attachments)
          ..where((t) => t.tripId.equals(tripId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }
}
