import 'dart:math' as math;
import '../../../database/database.dart';
import 'frequency_models.dart';

class FrequencyAnalytics {
  static FrequencySessionAuditSummary computeSessionSummary({
    required FrequencySessionEntry session,
    required List<FrequencyRecordWithDetails> records,
  }) {
    final startTime = session.startedAt;
    final endTime = session.endedAt ?? (records.isNotEmpty ? records.first.record.observedAt : DateTime.now());
    final durationSeconds = math.max(60, endTime.difference(startTime).inSeconds);
    final durationHours = durationSeconds / 3600.0;
    final totalDuration = Duration(seconds: durationSeconds);

    final totalSightings = records.length;
    final globalVehiclesPerHour = durationHours > 0 ? (totalSightings / durationHours) : 0.0;

    // Filter valid headways
    final validHeadways = records
        .map((r) => r.record.headwaySeconds)
        .whereType<int>()
        .where((s) => s > 0)
        .toList();

    double avgHeadwayMin = 0.0;
    double minHeadwayMin = 0.0;
    double maxHeadwayMin = 0.0;

    if (validHeadways.isNotEmpty) {
      final sum = validHeadways.reduce((a, b) => a + b);
      avgHeadwayMin = (sum / validHeadways.length) / 60.0;
      minHeadwayMin = validHeadways.reduce(math.min) / 60.0;
      maxHeadwayMin = validHeadways.reduce(math.max) / 60.0;
    }

    final totalBunching = records.where((r) => r.record.isBunching).length;
    final bunchingRate = totalSightings > 0 ? (totalBunching / totalSightings) * 100.0 : 0.0;

    final totalDelayed = records.where((r) => r.record.isDelayed).length;
    final delayedRate = totalSightings > 0 ? (totalDelayed / totalSightings) * 100.0 : 0.0;

    double avgLoad = 2.0;
    if (records.isNotEmpty) {
      final sumLoad = records.map((r) => r.record.passengerLoad).reduce((a, b) => a + b);
      avgLoad = sumLoad / records.length;
    }

    // Group by (lineId, branchId, direction)
    final Map<String, List<FrequencyRecordWithDetails>> groups = {};
    for (final r in records) {
      final key = '${r.line.id}_${r.branch.id}_${r.record.direction}';
      groups.putIfAbsent(key, () => []).add(r);
    }

    final branchStats = <FrequencyBranchStat>[];
    groups.forEach((key, groupRecords) {
      if (groupRecords.isEmpty) return;
      final line = groupRecords.first.line;
      final branch = groupRecords.first.branch;
      final direction = groupRecords.first.record.direction;

      final gSightings = groupRecords.length;
      final gVehPerHour = durationHours > 0 ? (gSightings / durationHours) : 0.0;

      final gHeadways = groupRecords
          .map((r) => r.record.headwaySeconds)
          .whereType<int>()
          .where((s) => s > 0)
          .toList();

      double gAvgH = 0.0;
      double gMinH = 0.0;
      double gMaxH = 0.0;

      if (gHeadways.isNotEmpty) {
        gAvgH = (gHeadways.reduce((a, b) => a + b) / gHeadways.length) / 60.0;
        gMinH = gHeadways.reduce(math.min) / 60.0;
        gMaxH = gHeadways.reduce(math.max) / 60.0;
      }

      final gBunching = groupRecords.where((r) => r.record.isBunching).length;
      final gDelayed = groupRecords.where((r) => r.record.isDelayed).length;
      final gAvgLoad = groupRecords.map((r) => r.record.passengerLoad).reduce((a, b) => a + b) / gSightings;

      branchStats.add(
        FrequencyBranchStat(
          line: line,
          branch: branch,
          direction: direction,
          totalSightings: gSightings,
          vehiclesPerHour: gVehPerHour,
          avgHeadwayMinutes: gAvgH,
          minHeadwayMinutes: gMinH,
          maxHeadwayMinutes: gMaxH,
          bunchingCount: gBunching,
          delayedCount: gDelayed,
          avgPassengerLoad: gAvgLoad,
        ),
      );
    });

    // Sort branchStats by total sightings desc
    branchStats.sort((a, b) => b.totalSightings.compareTo(a.totalSightings));

    return FrequencySessionAuditSummary(
      session: session,
      records: records,
      totalDuration: totalDuration,
      totalSightings: totalSightings,
      globalVehiclesPerHour: globalVehiclesPerHour,
      avgHeadwayMinutes: avgHeadwayMin,
      minHeadwayMinutes: minHeadwayMin,
      maxHeadwayMinutes: maxHeadwayMin,
      totalBunching: totalBunching,
      bunchingRatePercent: bunchingRate,
      totalDelayed: totalDelayed,
      delayedRatePercent: delayedRate,
      avgPassengerLoad: avgLoad,
      branchStats: branchStats,
    );
  }

  static String formatHeadway(int? seconds) {
    if (seconds == null || seconds <= 0) return 'Primer paso';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min == 0) return '${sec}s';
    if (sec == 0) return '$min min';
    return '$min min ${sec}s';
  }

  static String formatLoad(int load) {
    switch (load) {
      case 1:
        return 'Baja (Asientos libres)';
      case 2:
        return 'Media (Todos sentados)';
      case 3:
        return 'Alta (Pasajeros parados)';
      case 4:
        return 'Colapsado (Sobrecarga)';
      default:
        return 'Normal';
    }
  }
}
