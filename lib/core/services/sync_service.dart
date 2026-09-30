import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database.dart';
import '../constants/api_credentials.dart';

class SyncService {
  static const String serverUrlKey = 'lanus_server_url';

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(serverUrlKey) ?? LanusCredentials.defaultServerUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(serverUrlKey, cleanUrl);
  }

  /// Sincroniza un viaje hacia la base de datos de Lanús GIS vía HTTP POST
  static Future<bool> syncTrip({
    required AppDatabase db,
    required TripEntry trip,
    required LineEntry line,
    required BranchEntry branch,
    required List<TrackPointEntry> trackPoints,
    required List<StopEntry> stops,
    required List<IncidentEntry> incidents,
  }) async {
    try {
      final baseUrl = await getServerUrl();
      final endpoint = Uri.parse('$baseUrl${LanusCredentials.syncTripsPath}');

      // Puntos válidos (descartar OUTLIER)
      final validCoords = trackPoints
          .where((p) => p.quality != 'OUTLIER')
          .map((p) => [p.longitude, p.latitude, p.altitude ?? 0.0])
          .toList();

      final features = <Map<String, dynamic>>[];

      // 1. Línea de recorrido GPS (LineString)
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': validCoords,
        },
        'properties': {
          'name': '${line.number} - ${branch.name} (${trip.direction})',
          'line': line.number,
          'branch': branch.name,
          'direction': trip.direction,
          'startedAt': trip.startedAt.toIso8601String(),
          'endedAt': trip.endedAt?.toIso8601String(),
          'distanceMeters': trip.distanceMeters,
          'durationMs': trip.durationMs,
        },
      });

      // 2. Paradas relevadas
      for (final s in stops) {
        features.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [s.longitude, s.latitude],
          },
          'properties': {
            'type': 'stop',
            'sequence': s.sequence,
            'name': s.name ?? 'Parada ${s.sequence}',
            'dwellTimeMs': s.dwellTimeMs,
          },
        });
      }

      // 3. Incidencias
      for (final inc in incidents) {
        features.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [inc.longitude, inc.latitude],
          },
          'properties': {
            'type': 'incident',
            'incidentType': inc.type,
            'severity': inc.severity,
            'description': inc.description ?? '',
          },
        });
      }

      final payload = {
        'uuid': trip.id,
        'lineaNumero': line.number,
        'ramal': branch.name,
        'sentido': trip.direction,
        'interno': trip.internalNumber,
        'patente': trip.domain,
        'chofer': trip.driverName,
        'notas': trip.notes,
        'startedAt': trip.startedAt.toIso8601String(),
        'endedAt': trip.endedAt?.toIso8601String(),
        'distanceMeters': trip.distanceMeters,
        'durationMs': trip.durationMs,
        'averageSpeedKmh': trip.averageSpeedKmh,
        'maxSpeedKmh': trip.maxSpeedKmh,
        'pointCount': validCoords.length,
        'stopCount': stops.length,
        'incidentCount': incidents.length,
        'origen': 'APP_MOBILE',
        'datosGeo': {
          'type': 'FeatureCollection',
          'features': features,
        },
      };

      final response = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'X-App-Client': LanusCredentials.clientIdentifier,
          'X-API-Key': LanusCredentials.internalApiKey,
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final remoteId = resData['id']?.toString();

        await (db.update(db.trips)..where((t) => t.id.equals(trip.id))).write(
          TripsCompanion(
            syncStatus: const Value('SYNCED'),
            syncedAt: Value(DateTime.now()),
            remoteId: Value(remoteId),
          ),
        );
        return true;
      } else {
        await (db.update(db.trips)..where((t) => t.id.equals(trip.id))).write(
          const TripsCompanion(syncStatus: Value('FAILED')),
        );
        return false;
      }
    } catch (_) {
      await (db.update(db.trips)..where((t) => t.id.equals(trip.id))).write(
        const TripsCompanion(syncStatus: Value('FAILED')),
      );
      return false;
    }
  }

  /// Descarga el catálogo oficial de líneas y ramales de Lanús Digital
  static Future<int> fetchOfficialLines(AppDatabase db) async {
    try {
      final baseUrl = await getServerUrl();
      final endpoint = Uri.parse('$baseUrl${LanusCredentials.linesCatalogPath}');
      final response = await http.get(endpoint).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        int count = 0;

        for (final item in data) {
          final numero = (item['numero'] ?? item['nombre'] ?? '').toString();
          final ramal = (item['subcategoria'] ?? 'Principal').toString();

          if (numero.isEmpty) continue;

          final existingLine = await (db.select(db.lines)..where((l) => l.number.equals(numero))).getSingleOrNull();
          int lineId;

          if (existingLine == null) {
            lineId = await db.into(db.lines).insert(
                  LinesCompanion.insert(
                    number: numero,
                    name: item['nombre'] ?? 'Línea $numero',
                  ),
                );
          } else {
            lineId = existingLine.id;
          }

          final existingBranch = await (db.select(db.branches)
                ..where((b) => b.lineId.equals(lineId) & b.name.equals(ramal)))
              .getSingleOrNull();

          if (existingBranch == null) {
            await db.into(db.branches).insert(
                  BranchesCompanion.insert(
                    lineId: lineId,
                    name: ramal,
                  ),
                );
            count++;
          }
        }
        return count;
      }
    } catch (_) {}
    return 0;
  }
}
