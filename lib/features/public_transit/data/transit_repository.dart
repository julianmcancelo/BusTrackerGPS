import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';
import '../../../database/database.dart';
import '../../../database/database_provider.dart';
import '../../../core/utils/transport_utils.dart';
import '../../../core/utils/geo_utils.dart';
import 'models/transit_models.dart';

final transitRepositoryProvider = Provider<TransitRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransitRepository(db);
});

class TransitRepository {
  final AppDatabase db;

  TransitRepository(this.db);

  /// Obtiene la red completa de transporte municipal con sus ramales y trazas
  Future<List<TransitLineSummary>> getTransitNetwork() async {
    final lines = await (db.select(db.lines)
          ..orderBy([(l) => OrderingTerm.asc(l.number)]))
        .get();

    final result = <TransitLineSummary>[];

    for (final line in lines) {
      final branches = await (db.select(db.branches)
            ..where((b) => b.lineId.equals(line.id))
            ..orderBy([(b) => OrderingTerm.asc(b.name)]))
          .get();

      final branchSummaries = <TransitBranchSummary>[];

      for (final branch in branches) {
        final refRoutes = await (db.select(db.referenceRoutes)
              ..where((r) =>
                  r.lineId.equals(line.id) & r.branchId.equals(branch.id)))
            .get();

        ReferenceRouteEntry? idaRoute;
        ReferenceRouteEntry? vueltaRoute;
        List<LatLng> idaPoints = [];
        List<LatLng> vueltaPoints = [];
        double idaKm = 0.0;
        double vueltaKm = 0.0;

        for (final r in refRoutes) {
          final dir = r.direction.toUpperCase();
          final pts = GeoUtils.parseGeoJsonCoordinates(r.geoJsonData);
          final meters = GeoUtils.calculatePolylineDistanceMeters(pts);
          final km = meters / 1000.0;

          if (dir == 'IDA' && idaRoute == null) {
            idaRoute = r;
            idaPoints = pts;
            idaKm = km;
          } else if (dir == 'VUELTA' && vueltaRoute == null) {
            vueltaRoute = r;
            vueltaPoints = pts;
            vueltaKm = km;
          }
        }

        branchSummaries.add(TransitBranchSummary(
          branch: branch,
          idaRoute: idaRoute,
          vueltaRoute: vueltaRoute,
          idaPoints: idaPoints,
          vueltaPoints: vueltaPoints,
          idaDistanceKm: idaKm,
          vueltaDistanceKm: vueltaKm,
        ));
      }

      final color = TransportUtils.getLineColor(line.number);

      result.add(TransitLineSummary(
        line: line,
        color: color,
        branches: branchSummaries,
      ));
    }

    // Ordenamiento numérico canónico de todas las líneas (9, 10, 15, ..., 520, 527)
    result.sort((a, b) => TransportUtils.compareLineNumbers(a.number, b.number));

    return result;
  }

  /// Observa cambios en la red completa de transporte
  Stream<List<TransitLineSummary>> watchTransitNetwork() {
    // Escucha cambios en líneas y refresca la red
    return db.select(db.lines).watch().asyncMap((_) => getTransitNetwork());
  }

  /// Genera o consulta paradas a lo largo de un ramal
  Future<List<TransitStop>> getStopsForBranch({
    required TransitLineSummary line,
    required TransitBranchSummary branch,
    required TransitDirectionFilter direction,
  }) async {
    final stops = <TransitStop>[];
    final targetPoints = <LatLng>[];

    if (direction == TransitDirectionFilter.ida ||
        direction == TransitDirectionFilter.both) {
      targetPoints.addAll(branch.idaPoints);
    }
    if (direction == TransitDirectionFilter.vuelta ||
        (direction == TransitDirectionFilter.both && targetPoints.isEmpty)) {
      targetPoints.addAll(branch.vueltaPoints);
    }

    if (targetPoints.isEmpty) return [];

    // Muestreo representativo de paradas cada ~400-500 metros
    double accumulated = 0.0;
    int stopIndex = 1;

    // Terminal de origen
    stops.add(TransitStop(
      id: '${line.id}_${branch.branch.id}_start',
      name: 'Cabecera Inicial (${branch.branch.name})',
      position: targetPoints.first,
      lineNumbers: [line.number],
      direction: direction.label,
      sequence: stopIndex++,
    ));

    for (int i = 0; i < targetPoints.length - 1; i++) {
      final d = GeoUtils.distanceMeters(
        targetPoints[i].latitude,
        targetPoints[i].longitude,
        targetPoints[i + 1].latitude,
        targetPoints[i + 1].longitude,
      );
      accumulated += d;

      if (accumulated >= 450) {
        stops.add(TransitStop(
          id: '${line.id}_${branch.branch.id}_$i',
          name: 'Parada $stopIndex · L.${line.number}',
          position: targetPoints[i + 1],
          lineNumbers: [line.number],
          direction: direction.label,
          sequence: stopIndex++,
        ));
        accumulated = 0.0;
      }
    }

    // Terminal de destino
    if (targetPoints.length > 1) {
      stops.add(TransitStop(
        id: '${line.id}_${branch.branch.id}_end',
        name: 'Cabecera Final (${branch.branch.name})',
        position: targetPoints.last,
        lineNumbers: [line.number],
        direction: direction.label,
        sequence: stopIndex++,
      ));
    }

    return stops;
  }

  /// Calcula paradas y líneas cercanas a una posición geográfica
  Future<List<TransitStop>> getNearbyStops(
    LatLng userLocation, {
    double maxDistanceMeters = 600.0,
  }) async {
    final network = await getTransitNetwork();
    final candidateStops = <TransitStop>[];

    for (final line in network) {
      for (final branch in line.branches) {
        final allPoints = [...branch.idaPoints, ...branch.vueltaPoints];
        for (int i = 0; i < allPoints.length; i += 5) {
          final pt = allPoints[i];
          final dist = GeoUtils.distanceMeters(
            userLocation.latitude,
            userLocation.longitude,
            pt.latitude,
            pt.longitude,
          );
          if (dist <= maxDistanceMeters) {
            candidateStops.add(TransitStop(
              id: 'nearby_${line.id}_$i',
              name: 'Parada Línea ${line.number}',
              position: pt,
              lineNumbers: [line.number],
            ));
            break; // Una parada por ramal cercano es suficiente para la recomendación
          }
        }
      }
    }

    return candidateStops;
  }
}
