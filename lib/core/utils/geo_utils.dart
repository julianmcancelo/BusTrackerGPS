import 'dart:convert';
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

  static LatLng _normalizeCoordinate(double a, double b, {bool isStandardGeoJson = true}) {
    // GeoJSON default: a is longitude (X), b is latitude (Y)
    double lon = isStandardGeoJson ? a : b;
    double lat = isStandardGeoJson ? b : a;

    // Smart coordinate swap detection for Argentina / AMBA region:
    // Typical latitude in Argentina: -56.0 to -21.0 (Lanús: ~ -34.70)
    // Typical longitude in Argentina: -74.0 to -53.0 (Lanús: ~ -58.39)
    if (lon >= -56.0 && lon <= -21.0 && lat >= -75.0 && lat <= -53.0) {
      // Coordinates were inverted as [lat, lon] instead of [lon, lat]
      final temp = lat;
      lat = lon;
      lon = temp;
    } else if (lat < -90.0 || lat > 90.0) {
      // Out of latitude range, swap
      final temp = lat;
      lat = lon;
      lon = temp;
    }

    lat = lat.clamp(-90.0, 90.0);
    lon = lon.clamp(-180.0, 180.0);

    return LatLng(lat, lon);
  }

  static List<LatLng> parseGeoJsonCoordinates(dynamic data) {
    if (data == null) return [];
    try {
      dynamic jsonObj = data;
      if (data is String) {
        final trimmed = data.trim();
        if (trimmed.isEmpty || trimmed == 'null' || trimmed == '{}' || trimmed == '[]') return [];
        jsonObj = jsonDecode(trimmed);
        // Handle double-encoded JSON string
        if (jsonObj is String && (jsonObj.startsWith('{') || jsonObj.startsWith('['))) {
          jsonObj = jsonDecode(jsonObj);
        }
      }

      final points = <LatLng>[];

      void addPointFromList(List coords, {bool isStandardGeoJson = true}) {
        if (coords.length >= 2) {
          final a = (coords[0] as num).toDouble();
          final b = (coords[1] as num).toDouble();
          points.add(_normalizeCoordinate(a, b, isStandardGeoJson: isStandardGeoJson));
        }
      }

      void extractFromGeometry(Map<String, dynamic> geom) {
        final type = (geom['type'] ?? '').toString().toUpperCase();
        final coords = geom['coordinates'] ?? geom['points'] ?? geom['puntos'] ?? geom['trazas'] ?? geom['latlngs'];
        if (coords is List) {
          if (type == 'LINESTRING' || type.isEmpty) {
            for (final c in coords) {
              if (c is List) {
                addPointFromList(c, isStandardGeoJson: true);
              } else if (c is Map) {
                final lat = (c['lat'] ?? c['latitude'] ?? c['y'] as num?)?.toDouble();
                final lon = (c['lon'] ?? c['lng'] ?? c['longitude'] ?? c['x'] as num?)?.toDouble();
                if (lat != null && lon != null) {
                  points.add(_normalizeCoordinate(lon, lat, isStandardGeoJson: true));
                }
              }
            }
          } else if (type == 'MULTILINESTRING' || type == 'POLYGON') {
            for (final line in coords) {
              if (line is List) {
                for (final c in line) {
                  if (c is List) {
                    addPointFromList(c, isStandardGeoJson: true);
                  }
                }
              }
            }
          } else if (type == 'POINT') {
            addPointFromList(coords, isStandardGeoJson: true);
          }
        }
      }

      if (jsonObj is Map<String, dynamic>) {
        final type = (jsonObj['type'] ?? '').toString();
        if (type == 'FeatureCollection' && jsonObj['features'] is List) {
          for (final f in jsonObj['features']) {
            if (f is Map<String, dynamic>) {
              if (f['geometry'] is Map<String, dynamic>) {
                extractFromGeometry(f['geometry'] as Map<String, dynamic>);
              } else if (f.containsKey('coordinates')) {
                extractFromGeometry(f);
              }
            }
          }
        } else if (type == 'Feature' && jsonObj['geometry'] is Map<String, dynamic>) {
          extractFromGeometry(jsonObj['geometry'] as Map<String, dynamic>);
        } else if (jsonObj.containsKey('coordinates') || jsonObj.containsKey('points') || jsonObj.containsKey('trazas')) {
          extractFromGeometry(jsonObj);
        } else if (jsonObj['geometry'] is Map<String, dynamic>) {
          extractFromGeometry(jsonObj['geometry'] as Map<String, dynamic>);
        }
      } else if (jsonObj is List) {
        for (final item in jsonObj) {
          if (item is List) {
            // Nested or flat coordinate pair
            if (item.isNotEmpty && item[0] is List) {
              for (final sub in item) {
                if (sub is List) addPointFromList(sub);
              }
            } else {
              addPointFromList(item);
            }
          } else if (item is Map<String, dynamic>) {
            if (item.containsKey('geometry')) {
              extractFromGeometry(item['geometry'] as Map<String, dynamic>);
            } else {
              final lat = (item['lat'] ?? item['latitude'] ?? item['y'] as num?)?.toDouble();
              final lon = (item['lon'] ?? item['lng'] ?? item['longitude'] ?? item['x'] as num?)?.toDouble();
              if (lat != null && lon != null) {
                points.add(_normalizeCoordinate(lon, lat, isStandardGeoJson: true));
              }
            }
          }
        }
      }

      return points;
    } catch (_) {
      return [];
    }
  }

  static double calculatePolylineDistanceMeters(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distanceMeters(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total;
  }

  static String formatSpeed(double speedKmh) {
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }
}
