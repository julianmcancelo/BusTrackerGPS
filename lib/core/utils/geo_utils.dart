import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class GeoUtils {
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates Haversine distance between two coordinates in meters.
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  /// Determines if a new point is physically improbable (outlier) relative to previous point.
  static bool isOutlier({
    required double lastLat,
    required double lastLon,
    required DateTime lastTime,
    required double newLat,
    required double newLon,
    required DateTime newTime,
    double maxSpeedKmh = 140.0,
  }) {
    final seconds = newTime.difference(lastTime).inMilliseconds / 1000.0;
    if (seconds <= 0) return true; // duplicate or backwards timestamp

    final dist = distanceMeters(lastLat, lastLon, newLat, newLon);
    final speedKmh = (dist / seconds) * 3.6;

    return speedKmh > maxSpeedKmh;
  }

  /// Calculates total distance in meters from list of points, excluding outliers.
  static double calculateTotalDistanceMeters(
      List<({double lat, double lon, bool isOutlier})> points) {
    double total = 0.0;
    ({double lat, double lon, bool isOutlier})? prev;

    for (final p in points) {
      if (p.isOutlier) continue;
      if (prev != null) {
        total += distanceMeters(prev.lat, prev.lon, p.lat, p.lon);
      }
      prev = p;
    }
    return total;
  }

  /// Calculates minimum perpendicular distance from a point to a reference line string in meters.
  static double distanceToPolyline(
    LatLng point,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) {
      return distanceMeters(
          point.latitude, point.longitude, polyline.first.latitude, polyline.first.longitude);
    }

    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final p1 = polyline[i];
      final p2 = polyline[i + 1];
      final dist = _distanceToSegment(point, p1, p2);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }

  static double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final x = p.longitude;
    final y = p.latitude;
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;

    final dx = bx - ax;
    final dy = by - ay;

    if (dx == 0 && dy == 0) {
      return distanceMeters(y, x, ay, ax);
    }

    final t = ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);

    final nearestX = ax + clampedT * dx;
    final nearestY = ay + clampedT * dy;

    return distanceMeters(y, x, nearestY, nearestX);
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000.0).toStringAsFixed(2)} km';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  static String formatSpeed(double speedKmh) {
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }
}
