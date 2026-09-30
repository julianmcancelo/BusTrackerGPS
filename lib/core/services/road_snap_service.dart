import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoadSnapService {
  static final http.Client _client = http.Client();

  /// Snaps a single point to the nearest road using OSRM Nearest API.
  /// Falls back to the original point if offline or if service is unreachable.
  static Future<LatLng> snapNearest({
    required double lat,
    required double lng,
  }) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/nearest/v1/driving/$lng,$lat?number=1',
      );
      final response = await _client.get(
        url,
        headers: {'User-Agent': 'LanusDigital/1.0'},
      ).timeout(const Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['waypoints'] != null && (data['waypoints'] as List).isNotEmpty) {
          final wp = data['waypoints'][0];
          final loc = wp['location'];
          final snapLng = (loc[0] as num).toDouble();
          final snapLat = (loc[1] as num).toDouble();
          return LatLng(snapLat, snapLng);
        }
      }
    } catch (_) {
      // Offline fallback: returns original coordinate gracefully
    }
    return LatLng(lat, lng);
  }

  /// Matches a sequence of GPS coordinates to the street network using OSRM Match API.
  /// Returns a clean, street-aligned polyline.
  static Future<List<LatLng>> matchTripPolyline(List<LatLng> points) async {
    if (points.length < 2) return points;

    // Sample points if too large (OSRM match limit is typically 100 coordinates per request)
    final sampled = _samplePoints(points, maxPoints: 95);
    final coordStr = sampled.map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}').join(';');

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/match/v1/driving/$coordStr?overview=full&geometries=geojson&steps=false',
      );
      final response = await _client.get(
        url,
        headers: {'User-Agent': 'LanusDigital/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['matchings'] != null && (data['matchings'] as List).isNotEmpty) {
          final matchedPoints = <LatLng>[];
          for (final match in data['matchings']) {
            final geom = match['geometry'];
            if (geom != null && geom['coordinates'] != null) {
              final coords = geom['coordinates'] as List;
              for (final c in coords) {
                matchedPoints.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
              }
            }
          }
          if (matchedPoints.isNotEmpty) {
            return matchedPoints;
          }
        }
      }
    } catch (_) {
      // Offline fallback: returns input points
    }
    return points;
  }

  static List<LatLng> _samplePoints(List<LatLng> points, {int maxPoints = 95}) {
    if (points.length <= maxPoints) return points;
    final step = points.length / maxPoints;
    final sampled = <LatLng>[];
    for (int i = 0; i < maxPoints - 1; i++) {
      sampled.add(points[(i * step).floor()]);
    }
    sampled.add(points.last);
    return sampled;
  }
}
