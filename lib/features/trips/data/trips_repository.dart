import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../database/database.dart';
import '../../../database/database_provider.dart';

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepository(ref.watch(databaseProvider));
});

class TripWithDetails {
  final TripEntry trip;
  final LineEntry line;
  final BranchEntry branch;

  TripWithDetails({
    required this.trip,
    required this.line,
    required this.branch,
  });
}

class ReferenceRouteWithDetails {
  final ReferenceRouteEntry route;
  final LineEntry line;
  final BranchEntry branch;
  final double distanceMeters;
  final int pointCount;

  ReferenceRouteWithDetails({
    required this.route,
    required this.line,
    required this.branch,
    required this.distanceMeters,
    required this.pointCount,
  });
}

class BranchDirectionStatus {
  final bool hasIda;
  final bool hasVuelta;
  final TripWithDetails? lastIdaTrip;
  final TripWithDetails? lastVueltaTrip;
  final ReferenceRouteEntry? referenceIdaRoute;
  final ReferenceRouteEntry? referenceVueltaRoute;
  
  final List<LatLng> idaPoints;
  final List<LatLng> vueltaPoints;
  final double idaDistanceMeters;
  final double vueltaDistanceMeters;
  final bool isFromRemotePlatform;

  final List<LatLng> networkIdaPoints;
  final List<LatLng> networkVueltaPoints;
  final List<LatLng> localIdaPoints;
  final List<LatLng> localVueltaPoints;

  bool get isComplete => hasIda && hasVuelta;
  bool get hasAny => hasIda || hasVuelta;
  double get totalDistanceMeters => idaDistanceMeters + vueltaDistanceMeters;

  BranchDirectionStatus({
    required this.hasIda,
    required this.hasVuelta,
    this.lastIdaTrip,
    this.lastVueltaTrip,
    this.referenceIdaRoute,
    this.referenceVueltaRoute,
    this.idaPoints = const [],
    this.vueltaPoints = const [],
    this.networkIdaPoints = const [],
    this.networkVueltaPoints = const [],
    this.localIdaPoints = const [],
    this.localVueltaPoints = const [],
    this.idaDistanceMeters = 0.0,
    this.vueltaDistanceMeters = 0.0,
    this.isFromRemotePlatform = false,
  });
}

class TripsRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  TripsRepository(this.db);

  Future<TripEntry?> getActiveTrip() async {
    final query = db.select(db.trips)
      ..where((t) => t.status.isIn(['ACTIVE', 'PAUSED']));
    final results = await query.get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<TripWithDetails?> getTripWithDetails(String tripId) async {
    final query = db.select(db.trips).join([
      innerJoin(db.lines, db.lines.id.equalsExp(db.trips.lineId)),
      innerJoin(db.branches, db.branches.id.equalsExp(db.trips.branchId)),
    ])..where(db.trips.id.equals(tripId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return TripWithDetails(
      trip: row.readTable(db.trips),
      line: row.readTable(db.lines),
      branch: row.readTable(db.branches),
    );
  }

  Future<String> createTrip({
    required int lineId,
    required int branchId,
    required String direction,
    String? internalNumber,
    String? domain,
    String? driverName,
    String? notes,
  }) async {
    // Check if active trip exists
    final active = await getActiveTrip();
    if (active != null) {
      return active.id;
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await db.into(db.trips).insert(
          TripsCompanion.insert(
            id: id,
            lineId: lineId,
            branchId: branchId,
            direction: direction,
            internalNumber: Value(internalNumber),
            domain: Value(domain),
            driverName: Value(driverName),
            notes: Value(notes),
            status: const Value('ACTIVE'),
            startedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return id;
  }

  Future<void> updateTripStatus(String tripId, String status) async {
    await (db.update(db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTripStats({
    required String tripId,
    required int durationMs,
    required double distanceMeters,
    required int movingTimeMs,
    required int stoppedTimeMs,
    required double averageSpeedKmh,
    required double maxSpeedKmh,
    required int pointCount,
    required int stopCount,
    required int incidentCount,
  }) async {
    await (db.update(db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        durationMs: Value(durationMs),
        distanceMeters: Value(distanceMeters),
        movingTimeMs: Value(movingTimeMs),
        stoppedTimeMs: Value(stoppedTimeMs),
        averageSpeedKmh: Value(averageSpeedKmh),
        maxSpeedKmh: Value(maxSpeedKmh),
        pointCount: Value(pointCount),
        stopCount: Value(stopCount),
        incidentCount: Value(incidentCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> finishTrip({
    required String tripId,
    required int durationMs,
    required double distanceMeters,
    required int movingTimeMs,
    required int stoppedTimeMs,
    required double averageSpeedKmh,
    required double maxSpeedKmh,
    required int pointCount,
    required int stopCount,
    required int incidentCount,
  }) async {
    final now = DateTime.now();
    await (db.update(db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        status: const Value('FINISHED'),
        endedAt: Value(now),
        durationMs: Value(durationMs),
        distanceMeters: Value(distanceMeters),
        movingTimeMs: Value(movingTimeMs),
        stoppedTimeMs: Value(stoppedTimeMs),
        averageSpeedKmh: Value(averageSpeedKmh),
        maxSpeedKmh: Value(maxSpeedKmh),
        pointCount: Value(pointCount),
        stopCount: Value(stopCount),
        incidentCount: Value(incidentCount),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<TripWithDetails>> watchTrips({
    String? searchQuery,
    int? lineId,
    int? branchId,
    String? direction,
  }) {
    final query = db.select(db.trips).join([
      innerJoin(db.lines, db.lines.id.equalsExp(db.trips.lineId)),
      innerJoin(db.branches, db.branches.id.equalsExp(db.trips.branchId)),
    ])
      ..orderBy([OrderingTerm.desc(db.trips.startedAt)]);

    if (lineId != null) {
      query.where(db.trips.lineId.equals(lineId));
    }
    if (branchId != null) {
      query.where(db.trips.branchId.equals(branchId));
    }
    if (direction != null && direction.isNotEmpty) {
      query.where(db.trips.direction.equals(direction));
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final term = '%$searchQuery%';
      query.where(
        db.lines.number.like(term) |
            db.lines.name.like(term) |
            db.branches.name.like(term) |
            db.trips.internalNumber.like(term) |
            db.trips.domain.like(term),
      );
    }

    return query.watch().map((rows) {
      return rows.map((r) {
        return TripWithDetails(
          trip: r.readTable(db.trips),
          line: r.readTable(db.lines),
          branch: r.readTable(db.branches),
        );
      }).toList();
    });
  }

  Stream<List<ReferenceRouteWithDetails>> watchReferenceRoutes({
    String? searchQuery,
    int? lineId,
    int? branchId,
    String? direction,
  }) {
    final query = db.select(db.referenceRoutes).join([
      innerJoin(db.lines, db.lines.id.equalsExp(db.referenceRoutes.lineId)),
      innerJoin(db.branches, db.branches.id.equalsExp(db.referenceRoutes.branchId)),
    ])
      ..orderBy([OrderingTerm.asc(db.lines.number), OrderingTerm.asc(db.branches.name)]);

    if (lineId != null) {
      query.where(db.referenceRoutes.lineId.equals(lineId));
    }
    if (branchId != null) {
      query.where(db.referenceRoutes.branchId.equals(branchId));
    }
    if (direction != null && direction.isNotEmpty) {
      query.where(db.referenceRoutes.direction.equals(direction));
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final term = '%$searchQuery%';
      query.where(
        db.lines.number.like(term) |
            db.lines.name.like(term) |
            db.branches.name.like(term) |
            db.referenceRoutes.name.like(term),
      );
    }

    return query.watch().map((rows) {
      return rows.map((r) {
        final route = r.readTable(db.referenceRoutes);
        final line = r.readTable(db.lines);
        final branch = r.readTable(db.branches);
        final coords = GeoUtils.parseGeoJsonCoordinates(route.geoJsonData);
        final dist = GeoUtils.calculatePolylineDistanceMeters(coords);
        return ReferenceRouteWithDetails(
          route: route,
          line: line,
          branch: branch,
          distanceMeters: dist,
          pointCount: coords.length,
        );
      }).toList();
    });
  }

  Future<ReferenceRouteWithDetails?> getReferenceRouteWithDetails(int routeId) async {
    final query = db.select(db.referenceRoutes).join([
      innerJoin(db.lines, db.lines.id.equalsExp(db.referenceRoutes.lineId)),
      innerJoin(db.branches, db.branches.id.equalsExp(db.referenceRoutes.branchId)),
    ])..where(db.referenceRoutes.id.equals(routeId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final route = row.readTable(db.referenceRoutes);
    final coords = GeoUtils.parseGeoJsonCoordinates(route.geoJsonData);
    final dist = GeoUtils.calculatePolylineDistanceMeters(coords);

    return ReferenceRouteWithDetails(
      route: route,
      line: row.readTable(db.lines),
      branch: row.readTable(db.branches),
      distanceMeters: dist,
      pointCount: coords.length,
    );
  }

  Future<TripWithDetails?> getLastTripConfig() async {
    final query = db.select(db.trips).join([
      innerJoin(db.lines, db.lines.id.equalsExp(db.trips.lineId)),
      innerJoin(db.branches, db.branches.id.equalsExp(db.trips.branchId)),
    ])
      ..orderBy([OrderingTerm.desc(db.trips.startedAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return TripWithDetails(
      trip: row.readTable(db.trips),
      line: row.readTable(db.lines),
      branch: row.readTable(db.branches),
    );
  }

  Future<void> deleteTrip(String tripId) async {
    await (db.delete(db.trackPoints)..where((t) => t.tripId.equals(tripId))).go();
    await (db.delete(db.stops)..where((t) => t.tripId.equals(tripId))).go();
    await (db.delete(db.incidents)..where((t) => t.tripId.equals(tripId))).go();
    await (db.delete(db.attachments)..where((t) => t.tripId.equals(tripId))).go();
    await (db.delete(db.trips)..where((t) => t.id.equals(tripId))).go();
  }

  Future<BranchDirectionStatus> getBranchDirectionStatus(int lineId, int branchId) async {
    final query = db.select(db.trips).join([
      innerJoin(db.lines, db.lines.id.equalsExp(db.trips.lineId)),
      innerJoin(db.branches, db.branches.id.equalsExp(db.trips.branchId)),
    ])..where(db.trips.lineId.equals(lineId) &
            db.trips.branchId.equals(branchId) &
            db.trips.status.equals('FINISHED'));

    final rows = await query.get();

    TripWithDetails? lastIda;
    TripWithDetails? lastVuelta;

    for (final r in rows) {
      final trip = r.readTable(db.trips);
      final line = r.readTable(db.lines);
      final branch = r.readTable(db.branches);
      final details = TripWithDetails(trip: trip, line: line, branch: branch);

      if (trip.direction == 'IDA' && lastIda == null) {
        lastIda = details;
      } else if (trip.direction == 'VUELTA' && lastVuelta == null) {
        lastVuelta = details;
      }
    }

    // Query ReferenceRoutes from municipal catalog / server sync
    final refQuery = db.select(db.referenceRoutes)
      ..where((r) => r.lineId.equals(lineId) & r.branchId.equals(branchId));
    final refRoutes = await refQuery.get();

    ReferenceRouteEntry? refIda;
    ReferenceRouteEntry? refVuelta;

    for (final rf in refRoutes) {
      if (rf.direction.toUpperCase() == 'IDA' && refIda == null) {
        refIda = rf;
      } else if (rf.direction.toUpperCase() == 'VUELTA' && refVuelta == null) {
        refVuelta = rf;
      }
    }

    // Resolve IDA coordinates
    List<LatLng> networkIdaCoords = [];
    List<LatLng> localIdaCoords = [];
    double idaDist = 0.0;
    final bool hasIda = lastIda != null || refIda != null;

    if (refIda != null) {
      networkIdaCoords = GeoUtils.parseGeoJsonCoordinates(refIda.geoJsonData);
      idaDist = GeoUtils.calculatePolylineDistanceMeters(networkIdaCoords);
    }
    
    if (lastIda != null) {
      final tripId = lastIda.trip.id;
      final rawPts = await (db.select(db.trackPoints)
            ..where((t) => t.tripId.equals(tripId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();
      localIdaCoords = rawPts
          .where((p) => p.quality != 'OUTLIER')
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      if (refIda == null) {
        idaDist = lastIda.trip.distanceMeters;
      }
    }

    // Resolve VUELTA coordinates
    List<LatLng> networkVueltaCoords = [];
    List<LatLng> localVueltaCoords = [];
    double vueltaDist = 0.0;
    final bool hasVuelta = lastVuelta != null || refVuelta != null;

    if (refVuelta != null) {
      networkVueltaCoords = GeoUtils.parseGeoJsonCoordinates(refVuelta.geoJsonData);
      vueltaDist = GeoUtils.calculatePolylineDistanceMeters(networkVueltaCoords);
    }
    
    if (lastVuelta != null) {
      final tripId = lastVuelta.trip.id;
      final rawPts = await (db.select(db.trackPoints)
            ..where((t) => t.tripId.equals(tripId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();
      localVueltaCoords = rawPts
          .where((p) => p.quality != 'OUTLIER')
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      if (refVuelta == null) {
        vueltaDist = lastVuelta.trip.distanceMeters;
      }
    }

    final isRemote = (refIda != null && lastIda == null) || (refVuelta != null && lastVuelta == null);

    return BranchDirectionStatus(
      hasIda: hasIda,
      hasVuelta: hasVuelta,
      lastIdaTrip: lastIda,
      lastVueltaTrip: lastVuelta,
      referenceIdaRoute: refIda,
      referenceVueltaRoute: refVuelta,
      idaPoints: networkIdaCoords.isNotEmpty ? networkIdaCoords : localIdaCoords,
      vueltaPoints: networkVueltaCoords.isNotEmpty ? networkVueltaCoords : localVueltaCoords,
      networkIdaPoints: networkIdaCoords,
      networkVueltaPoints: networkVueltaCoords,
      localIdaPoints: localIdaCoords,
      localVueltaPoints: localVueltaCoords,
      idaDistanceMeters: idaDist,
      vueltaDistanceMeters: vueltaDist,
      isFromRemotePlatform: isRemote,
    );
  }
}
