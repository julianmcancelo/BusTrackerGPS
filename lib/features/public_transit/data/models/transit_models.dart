import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../database/database.dart';

enum TransitDirectionFilter {
  both,
  ida,
  vuelta;

  String get label {
    switch (this) {
      case TransitDirectionFilter.both:
        return 'AMBOS';
      case TransitDirectionFilter.ida:
        return 'IDA';
      case TransitDirectionFilter.vuelta:
        return 'VUELTA';
    }
  }
}

class TransitBranchSummary {
  final BranchEntry branch;
  final ReferenceRouteEntry? idaRoute;
  final ReferenceRouteEntry? vueltaRoute;
  final List<LatLng> idaPoints;
  final List<LatLng> vueltaPoints;
  final double idaDistanceKm;
  final double vueltaDistanceKm;

  const TransitBranchSummary({
    required this.branch,
    this.idaRoute,
    this.vueltaRoute,
    this.idaPoints = const [],
    this.vueltaPoints = const [],
    this.idaDistanceKm = 0.0,
    this.vueltaDistanceKm = 0.0,
  });

  bool get hasAnyRoute => idaPoints.isNotEmpty || vueltaPoints.isNotEmpty;
  double get totalDistanceKm => idaDistanceKm + vueltaDistanceKm;
}

class TransitLineSummary {
  final LineEntry line;
  final Color color;
  final List<TransitBranchSummary> branches;

  const TransitLineSummary({
    required this.line,
    required this.color,
    required this.branches,
  });

  int get id => line.id;
  String get number => line.number;
  String get name => line.name;
  bool get hasRoutes => branches.any((b) => b.hasAnyRoute);

  TransitBranchSummary? get primaryBranch =>
      branches.isNotEmpty ? branches.first : null;
}

class TransitStop {
  final String id;
  final String name;
  final LatLng position;
  final List<String> lineNumbers;
  final String? direction;
  final int? sequence;

  const TransitStop({
    required this.id,
    required this.name,
    required this.position,
    required this.lineNumbers,
    this.direction,
    this.sequence,
  });
}
