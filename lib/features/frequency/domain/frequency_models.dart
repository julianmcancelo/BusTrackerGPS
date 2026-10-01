import '../../../database/database.dart';

class FrequencyRecordWithDetails {
  final FrequencyRecordEntry record;
  final LineEntry line;
  final BranchEntry branch;

  FrequencyRecordWithDetails({
    required this.record,
    required this.line,
    required this.branch,
  });
}

class FrequencyBranchStat {
  final LineEntry line;
  final BranchEntry branch;
  final String direction;
  final int totalSightings;
  final double vehiclesPerHour;
  final double avgHeadwayMinutes;
  final double minHeadwayMinutes;
  final double maxHeadwayMinutes;
  final int bunchingCount;
  final int delayedCount;
  final double avgPassengerLoad;

  FrequencyBranchStat({
    required this.line,
    required this.branch,
    required this.direction,
    required this.totalSightings,
    required this.vehiclesPerHour,
    required this.avgHeadwayMinutes,
    required this.minHeadwayMinutes,
    required this.maxHeadwayMinutes,
    required this.bunchingCount,
    required this.delayedCount,
    required this.avgPassengerLoad,
  });
}

class FrequencySessionAuditSummary {
  final FrequencySessionEntry session;
  final List<FrequencyRecordWithDetails> records;
  final Duration totalDuration;
  final int totalSightings;
  final double globalVehiclesPerHour;
  final double avgHeadwayMinutes;
  final double minHeadwayMinutes;
  final double maxHeadwayMinutes;
  final int totalBunching;
  final double bunchingRatePercent;
  final int totalDelayed;
  final double delayedRatePercent;
  final double avgPassengerLoad;
  final List<FrequencyBranchStat> branchStats;

  FrequencySessionAuditSummary({
    required this.session,
    required this.records,
    required this.totalDuration,
    required this.totalSightings,
    required this.globalVehiclesPerHour,
    required this.avgHeadwayMinutes,
    required this.minHeadwayMinutes,
    required this.maxHeadwayMinutes,
    required this.totalBunching,
    required this.bunchingRatePercent,
    required this.totalDelayed,
    required this.delayedRatePercent,
    required this.avgPassengerLoad,
    required this.branchStats,
  });
}
