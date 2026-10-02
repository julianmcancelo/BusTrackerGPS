import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:geolocator/geolocator.dart';

import 'package:bitacora_gps/database/database.dart';
import 'package:bitacora_gps/core/utils/geo_utils.dart';
import 'package:bitacora_gps/core/utils/kalman_filter.dart';
import 'package:bitacora_gps/core/utils/transport_utils.dart';
import 'package:bitacora_gps/core/services/sync_service.dart';
import 'package:bitacora_gps/features/export/data/export_service.dart';
import 'package:bitacora_gps/features/trips/data/trips_repository.dart';
import 'package:bitacora_gps/features/capture/data/gps_repository.dart';
import 'package:bitacora_gps/features/public_transit/data/transit_repository.dart';
import 'package:bitacora_gps/features/transport/data/transport_repository.dart';

void main() {
  group('GeoUtils Tests', () {
    test('Haversine distance calculation is accurate', () {
      // Distance between Obelisco Buenos Aires and Plaza de Mayo (~1.2 km)
      final dist = GeoUtils.distanceMeters(-34.6037, -58.3816, -34.6084, -58.3721);
      expect(dist, greaterThan(900));
      expect(dist, lessThan(1500));
    });

    test('Outlier detection identifies physically impossible speed jumps', () {
      final now = DateTime.now();
      final lastTime = now.subtract(const Duration(seconds: 2));

      // 50 km jump in 2 seconds -> extreme outlier
      final isOut = GeoUtils.isOutlier(
        lastLat: -34.600,
        lastLon: -58.380,
        lastTime: lastTime,
        newLat: -34.100,
        newLon: -58.100,
        newTime: now,
      );

      expect(isOut, isTrue);
    });

    test('Valid movement within speed limit is accepted', () {
      final now = DateTime.now();
      final lastTime = now.subtract(const Duration(seconds: 5));

      // 30 meters in 5 seconds = 21.6 km/h -> valid movement
      final isOut = GeoUtils.isOutlier(
        lastLat: -34.6000,
        lastLon: -58.3800,
        lastTime: lastTime,
        newLat: -34.6002,
        newLon: -58.3802,
        newTime: now,
      );

      expect(isOut, isFalse);
    });

    test('Formatting duration and distance', () {
      expect(GeoUtils.formatDistance(450), '450 m');
      expect(GeoUtils.formatDistance(12420), '12.42 km');
      expect(GeoUtils.formatDuration(const Duration(minutes: 42, seconds: 17)), '42:17');
    });

    test('Kalman Filter reduces GPS jitter while tracking motion', () {
      final kalman = GpsKalmanFilter();
      final p1 = kalman.process(lat: -34.7000, lng: -58.3800, accuracyMeters: 20.0, timestampMs: 1000);
      expect(p1.latitude, -34.7000);

      // Add noisy observation with high inaccuracy (50m)
      final p2 = kalman.process(lat: -34.7008, lng: -58.3800, accuracyMeters: 50.0, timestampMs: 2000);
      // Smoothed latitude should not blindly jump all the way to -34.7008
      expect(p2.latitude, greaterThan(-34.7008));
      expect(p2.latitude, lessThan(-34.7000));
    });
  });

  group('TransportUtils Tests', () {
    test('Identifies National lines correctly (1 to 199)', () {
      expect(TransportUtils.isNationalLine('9'), isTrue);
      expect(TransportUtils.isNationalLine('100'), isTrue);
      expect(TransportUtils.isNationalLine('160'), isTrue);
      expect(TransportUtils.isNationalLine('178'), isTrue);
      expect(TransportUtils.isNationalLine('271'), isFalse);
      expect(TransportUtils.isNationalLine('520'), isFalse);
    });

    test('Identifies Municipal lines correctly (500 to 599)', () {
      expect(TransportUtils.isMunicipalLine('520'), isTrue);
      expect(TransportUtils.isMunicipalLine('522'), isTrue);
      expect(TransportUtils.isMunicipalLine('527'), isTrue);
      expect(TransportUtils.isMunicipalLine('160'), isFalse);
      expect(TransportUtils.isMunicipalLine('271'), isFalse);
    });

    test('Identifies Provincial lines correctly (200 to 499)', () {
      expect(TransportUtils.isProvincialLine('247'), isTrue);
      expect(TransportUtils.isProvincialLine('271'), isTrue);
      expect(TransportUtils.isProvincialLine('318'), isTrue);
      expect(TransportUtils.isProvincialLine('9'), isFalse);
      expect(TransportUtils.isProvincialLine('520'), isFalse);
    });

    test('Returns appropriate jurisdiction label', () {
      expect(TransportUtils.getJurisdictionLabel('9'), 'Nacional');
      expect(TransportUtils.getJurisdictionLabel('271'), 'Provincial');
      expect(TransportUtils.getJurisdictionLabel('520'), 'Municipal');
    });
  });

  group('Drift Database & Repositories In-Memory Tests', () {
    late AppDatabase db;
    late TripsRepository tripsRepo;
    late GpsRepository gpsRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      tripsRepo = TripsRepository(db);
      gpsRepo = GpsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Create trip, insert track points, stops, and query back', () async {
      // Create test line & branch
      final lineId = await db.into(db.lines).insert(
            LinesCompanion.insert(number: '526', name: 'Línea 526'),
          );
      final branchId = await db.into(db.branches).insert(
            BranchesCompanion.insert(lineId: lineId, name: 'Principal'),
          );

      // Create active trip
      final tripId = await tripsRepo.createTrip(
        lineId: lineId,
        branchId: branchId,
        direction: 'IDA',
        internalNumber: '1234',
        domain: 'AB123CD',
      );

      expect(tripId, isNotEmpty);

      // Insert GPS Track Points
      final pos1 = Position(
        latitude: -34.700,
        longitude: -58.380,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 90.0,
        headingAccuracy: 1.0,
        speed: 10.0,
        speedAccuracy: 1.0,
      );

      await gpsRepo.insertTrackPoint(
        tripId: tripId,
        position: pos1,
        maxAccuracyThreshold: 50.0,
      );

      // Insert Stop
      await gpsRepo.insertStop(
        tripId: tripId,
        latitude: -34.700,
        longitude: -58.380,
        name: 'Parada 1',
      );

      // Verify active trip recovery
      final active = await tripsRepo.getActiveTrip();
      expect(active, isNotNull);
      expect(active!.id, tripId);
      expect(active.status, 'ACTIVE');

      // Verify details
      final details = await tripsRepo.getTripWithDetails(tripId);
      expect(details, isNotNull);
      expect(details!.line.number, '526');
      expect(details.branch.name, 'Principal');

      // Finish trip
      await tripsRepo.finishTrip(
        tripId: tripId,
        durationMs: 3600000,
        distanceMeters: 12400.0,
        movingTimeMs: 3000000,
        stoppedTimeMs: 600000,
        averageSpeedKmh: 22.5,
        maxSpeedKmh: 45.0,
        pointCount: 100,
        stopCount: 1,
        incidentCount: 0,
      );

      final finishedTrip = await tripsRepo.getTripWithDetails(tripId);
      expect(finishedTrip!.trip.status, 'FINISHED');
      expect(finishedTrip.trip.distanceMeters, 12400.0);
    });

    test('Export Service generates valid GeoJSON, GPX, KML and CSV', () async {
      final lineId = await db.into(db.lines).insert(LinesCompanion.insert(number: '526', name: 'Línea 526'));
      final branchId = await db.into(db.branches).insert(BranchesCompanion.insert(lineId: lineId, name: 'Principal'));

      final tripId = await tripsRepo.createTrip(lineId: lineId, branchId: branchId, direction: 'IDA');
      final details = (await tripsRepo.getTripWithDetails(tripId))!;

      final points = <TrackPointEntry>[];
      final stops = <StopEntry>[];
      final incidents = <IncidentEntry>[];

      final geoJson = await ExportService.generateGeoJson(
        trip: details.trip,
        line: details.line,
        branch: details.branch,
        trackPoints: points,
        stops: stops,
        incidents: incidents,
      );
      expect(geoJson, contains('FeatureCollection'));

      final gpx = await ExportService.generateGpx(
        trip: details.trip,
        line: details.line,
        branch: details.branch,
        trackPoints: points,
        stops: stops,
        incidents: incidents,
      );
      expect(gpx, contains('<gpx'));

      final kml = await ExportService.generateKml(
        trip: details.trip,
        line: details.line,
        branch: details.branch,
        trackPoints: points,
        stops: stops,
        incidents: incidents,
      );
      expect(kml, contains('<kml'));

      final csvMap = await ExportService.generateCsv(
        trip: details.trip,
        trackPoints: points,
        stops: stops,
        incidents: incidents,
      );
      expect(csvMap.containsKey('track_points.csv'), isTrue);
    });

    test('Lanus Digital Catalog import and Transit Network isolation', () async {
      await db.seedInitialTransportData();

      // Sample mock data representing Lanus Digital API lines (municipal 520 and non-municipal 9)
      final sampleLanusDigitalData = [
        {
          'numero': '9',
          'nombre': 'Línea 9 (General Tomás Guido)',
          'subcategoria': 'Ramal 1',
          'sentido': 'IDA',
          'datosGeo': {
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [-58.3745, -34.5854],
                [-58.3734, -34.5860],
                [-58.4250, -34.6926],
              ]
            }
          }
        },
        {
          'numero': '9',
          'nombre': 'Línea 9 (General Tomás Guido)',
          'subcategoria': 'Ramal 1',
          'sentido': 'VUELTA',
          'datosGeo': {
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [-58.4250, -34.6926],
                [-58.3734, -34.5860],
                [-58.3745, -34.5854],
              ]
            }
          }
        },
        {
          'numero': '520',
          'nombre': 'Línea 520 (Micro Ómnibus Lanús)',
          'subcategoria': 'Ramal B',
          'sentido': 'IDA',
          'datosGeo': {
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [-58.3920, -34.7050],
                [-58.3890, -34.7080],
                [-58.3810, -34.7160],
              ]
            }
          }
        },
      ];

      final imported = await SyncService.importCatalogData(db, sampleLanusDigitalData);
      expect(imported, greaterThan(0));

      final transitRepo = TransitRepository(db);
      final transitNetwork = await transitRepo.getTransitNetwork();

      // In Public Transit, BOTH lines (9 and 520) must be present because they have valid routes
      expect(transitNetwork.any((l) => l.number == '9'), isTrue);
      expect(transitNetwork.any((l) => l.number == '520'), isTrue);

      final line9 = transitNetwork.firstWhere((l) => l.number == '9');
      expect(line9.hasRoutes, isTrue);
      expect(line9.primaryBranch?.idaPoints.length, 3);
      expect(line9.primaryBranch?.vueltaPoints.length, 3);

      // In TransportRepository (Inspector Field Survey), ONLY municipal line 520 must appear, NOT Line 9
      final transportRepo = TransportRepository(db);
      final fieldSurveyLines = await transportRepo.getAllLines();
      expect(fieldSurveyLines.any((l) => l.number == '520'), isTrue);
      expect(fieldSurveyLines.any((l) => l.number == '9'), isFalse);
    });
  });
}
