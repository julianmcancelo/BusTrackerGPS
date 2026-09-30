import 'package:geolocator/geolocator.dart';
import '../../../database/database.dart';

enum CaptureStatus {
  idle,
  starting,
  active,
  paused,
  stopping,
  finished,
  error,
}

class CaptureState {
  final CaptureStatus status;
  final String? tripId;
  final LineEntry? line;
  final BranchEntry? branch;
  final String direction; // 'IDA' or 'VUELTA'
  final String? internalNumber;
  final String? domain;
  final String? driverName;

  final Position? currentPosition;
  final Position? lastAcceptedPosition;

  final int pointCount;
  final int stopCount;
  final int incidentCount;

  final double totalDistanceMeters;
  final int elapsedSeconds;
  final double currentSpeedKmh;
  final double avgSpeedKmh;
  final double maxSpeedKmh;

  final int movingTimeSeconds;
  final int stoppedTimeSeconds;

  final String gpsSignalQuality; // 'EXCELLENT', 'GOOD', 'LOW', 'NO_SIGNAL'
  final DateTime? lastGpsUpdate;

  final bool possibleStopDetected;
  final int possibleStopSeconds;

  final bool deviationAlert;
  final double deviationDistanceMeters;
  final ReferenceRouteEntry? referenceRoute;

  final String? errorMessage;

  const CaptureState({
    this.status = CaptureStatus.idle,
    this.tripId,
    this.line,
    this.branch,
    this.direction = 'IDA',
    this.internalNumber,
    this.domain,
    this.driverName,
    this.currentPosition,
    this.lastAcceptedPosition,
    this.pointCount = 0,
    this.stopCount = 0,
    this.incidentCount = 0,
    this.totalDistanceMeters = 0.0,
    this.elapsedSeconds = 0,
    this.currentSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.movingTimeSeconds = 0,
    this.stoppedTimeSeconds = 0,
    this.gpsSignalQuality = 'NO_SIGNAL',
    this.lastGpsUpdate,
    this.possibleStopDetected = false,
    this.possibleStopSeconds = 0,
    this.deviationAlert = false,
    this.deviationDistanceMeters = 0.0,
    this.referenceRoute,
    this.errorMessage,
  });

  CaptureState copyWith({
    CaptureStatus? status,
    String? tripId,
    LineEntry? line,
    BranchEntry? branch,
    String? direction,
    String? internalNumber,
    String? domain,
    String? driverName,
    Position? currentPosition,
    Position? lastAcceptedPosition,
    int? pointCount,
    int? stopCount,
    int? incidentCount,
    double? totalDistanceMeters,
    int? elapsedSeconds,
    double? currentSpeedKmh,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    int? movingTimeSeconds,
    int? stoppedTimeSeconds,
    String? gpsSignalQuality,
    DateTime? lastGpsUpdate,
    bool? possibleStopDetected,
    int? possibleStopSeconds,
    bool? deviationAlert,
    double? deviationDistanceMeters,
    ReferenceRouteEntry? referenceRoute,
    String? errorMessage,
  }) {
    return CaptureState(
      status: status ?? this.status,
      tripId: tripId ?? this.tripId,
      line: line ?? this.line,
      branch: branch ?? this.branch,
      direction: direction ?? this.direction,
      internalNumber: internalNumber ?? this.internalNumber,
      domain: domain ?? this.domain,
      driverName: driverName ?? this.driverName,
      currentPosition: currentPosition ?? this.currentPosition,
      lastAcceptedPosition: lastAcceptedPosition ?? this.lastAcceptedPosition,
      pointCount: pointCount ?? this.pointCount,
      stopCount: stopCount ?? this.stopCount,
      incidentCount: incidentCount ?? this.incidentCount,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      movingTimeSeconds: movingTimeSeconds ?? this.movingTimeSeconds,
      stoppedTimeSeconds: stoppedTimeSeconds ?? this.stoppedTimeSeconds,
      gpsSignalQuality: gpsSignalQuality ?? this.gpsSignalQuality,
      lastGpsUpdate: lastGpsUpdate ?? this.lastGpsUpdate,
      possibleStopDetected: possibleStopDetected ?? this.possibleStopDetected,
      possibleStopSeconds: possibleStopSeconds ?? this.possibleStopSeconds,
      deviationAlert: deviationAlert ?? this.deviationAlert,
      deviationDistanceMeters: deviationDistanceMeters ?? this.deviationDistanceMeters,
      referenceRoute: referenceRoute ?? this.referenceRoute,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
