import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'LANÚS DIGITAL';

  // Default GPS parameters
  static const int defaultIntervalSeconds = 2;
  static const double defaultMinDistanceMeters = 3.0;
  static const double defaultMaxAccuracyMeters = 50.0;

  // Auto stop detection defaults
  static const int defaultAutoStopMinTimeSeconds = 20;
  static const double defaultAutoStopMaxSpeedKmh = 2.0;

  // Deviation threshold
  static const double defaultDeviationThresholdMeters = 100.0;
}

enum TripStatus { draft, active, paused, finished }

enum PointQuality { good, lowAccuracy, outlier }

enum StopStatus { manual, autoDetected, confirmed, ignored }

enum IncidentType {
  obra,
  corte,
  desvio,
  transito,
  parada,
  calzada,
  unidad,
  accidente,
  otro,
}

extension IncidentTypeX on IncidentType {
  String get label {
    switch (this) {
      case IncidentType.obra:
        return 'Obra';
      case IncidentType.corte:
        return 'Corte de calle';
      case IncidentType.desvio:
        return 'Desvío de ruta';
      case IncidentType.transito:
        return 'Tránsito lento';
      case IncidentType.parada:
        return 'Parada bloqueada';
      case IncidentType.calzada:
        return 'Estado de calzada';
      case IncidentType.unidad:
        return 'Falla de unidad';
      case IncidentType.accidente:
        return 'Accidente';
      case IncidentType.otro:
        return 'Otro';
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentType.obra:
        return Icons.construction;
      case IncidentType.corte:
        return Icons.block;
      case IncidentType.desvio:
        return Icons.alt_route;
      case IncidentType.transito:
        return Icons.traffic;
      case IncidentType.parada:
        return Icons.front_hand;
      case IncidentType.calzada:
        return Icons.report_problem;
      case IncidentType.unidad:
        return Icons.bus_alert;
      case IncidentType.accidente:
        return Icons.car_crash;
      case IncidentType.otro:
        return Icons.warning_amber;
    }
  }
}

enum IncidentSeverity { low, medium, high, critical }

extension IncidentSeverityX on IncidentSeverity {
  String get label {
    switch (this) {
      case IncidentSeverity.low:
        return 'Baja';
      case IncidentSeverity.medium:
        return 'Media';
      case IncidentSeverity.high:
        return 'Alta';
      case IncidentSeverity.critical:
        return 'Crítica';
    }
  }
}

enum MovementStatus { moving, stopped, unknown }

enum AttachmentType { photo, audio, file }
