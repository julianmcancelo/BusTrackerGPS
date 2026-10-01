import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class StreetItineraryService {
  static final http.Client _client = http.Client();
  static final Map<String, List<String>> _cache = {};

  /// Extrae la secuencia ordenada de arterias y avenidas de un recorrido GPS
  /// utilizando el motor OpenStreetMap (OSRM Match & Nearest).
  static Future<List<String>> extractStreetSequence(List<LatLng> points) async {
    if (points.length < 2) return const [];

    final cacheKey = '${points.length}_${points.first.latitude.toStringAsFixed(4)}_${points.last.longitude.toStringAsFixed(4)}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // 1. Muestrear puntos para no exceder los límites de OSRM (máx 80 puntos por request)
      final sampled = _samplePoints(points, maxPoints: 70);
      final coordStr = sampled
          .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
          .join(';');

      final matchUrl = Uri.parse(
        'https://router.project-osrm.org/match/v1/driving/$coordStr?overview=false&steps=true',
      );

      final response = await _client.get(
        matchUrl,
        headers: {'User-Agent': 'LanusDigitalCartography/1.0'},
      ).timeout(const Duration(milliseconds: 3500));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['matchings'] != null) {
          final streets = <String>[];
          for (final matching in data['matchings']) {
            final legs = matching['legs'] as List?;
            if (legs == null) continue;
            for (final leg in legs) {
              final steps = leg['steps'] as List?;
              if (steps == null) continue;
              for (final step in steps) {
                final name = (step['name'] as String?)?.trim();
                if (name != null &&
                    name.isNotEmpty &&
                    !name.toLowerCase().contains('unnamed') &&
                    (streets.isEmpty || streets.last.toLowerCase() != name.toLowerCase())) {
                  streets.add(_cleanStreetName(name));
                }
              }
            }
          }

          if (streets.isNotEmpty) {
            _cache[cacheKey] = streets;
            return streets;
          }
        }
      }
    } catch (_) {
      // Si falla OSRM match (e.g. timeout de red), intentar fallback con nearest
    }

    // Fallback: muestreo de puntos clave y consulta nearest
    try {
      final fallbackStreets = await _fallbackNearestStreets(points);
      if (fallbackStreets.isNotEmpty) {
        _cache[cacheKey] = fallbackStreets;
        return fallbackStreets;
      }
    } catch (_) {}

    return const [];
  }

  static Future<List<String>> _fallbackNearestStreets(List<LatLng> points) async {
    final sampled = _samplePoints(points, maxPoints: 12);
    final streets = <String>[];

    for (final pt in sampled) {
      try {
        final url = Uri.parse(
          'https://router.project-osrm.org/nearest/v1/driving/${pt.longitude.toStringAsFixed(6)},${pt.latitude.toStringAsFixed(6)}?number=1',
        );
        final res = await _client.get(
          url,
          headers: {'User-Agent': 'LanusDigitalCartography/1.0'},
        ).timeout(const Duration(milliseconds: 1200));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['code'] == 'Ok' && data['waypoints'] != null && (data['waypoints'] as List).isNotEmpty) {
            final name = (data['waypoints'][0]['name'] as String?)?.trim();
            if (name != null &&
                name.isNotEmpty &&
                !name.toLowerCase().contains('unnamed') &&
                (streets.isEmpty || streets.last.toLowerCase() != name.toLowerCase())) {
              streets.add(_cleanStreetName(name));
            }
          }
        }
      } catch (_) {}
    }
    return streets;
  }

  static String _cleanStreetName(String raw) {
    var s = raw.trim();
    // Normalizar abreviaturas comunes para mayor legibilidad cartográfica
    if (s.startsWith('Avenida ')) {
      s = 'Av. ${s.substring(8)}';
    } else if (s.startsWith('Coronel ')) {
      s = 'Cnel. ${s.substring(8)}';
    } else if (s.startsWith('General ')) {
      s = 'Gral. ${s.substring(8)}';
    } else if (s.startsWith('Teniente ')) {
      s = 'Tte. ${s.substring(9)}';
    } else if (s.startsWith('Doctor ')) {
      s = 'Dr. ${s.substring(7)}';
    }
    return s;
  }

  static List<LatLng> _samplePoints(List<LatLng> points, {int maxPoints = 70}) {
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
