import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database.dart';
import '../constants/api_credentials.dart';
import '../utils/transport_utils.dart';

class SyncResult {
  final bool success;
  final String? message;
  final int? statusCode;
  final String serverUrl;

  const SyncResult({
    required this.success,
    this.message,
    this.statusCode,
    required this.serverUrl,
  });
}

class SyncService {
  static const String serverUrlKey = 'lanus_server_url';

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(serverUrlKey);
    if (saved == null ||
        saved.contains('lanusgis-ca546') ||
        saved == 'https://lanus.digital' ||
        saved == 'http://lanus.digital') {
      return LanusCredentials.defaultServerUrl;
    }
    return saved;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    var cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleanUrl == 'https://lanus.digital' || cleanUrl == 'http://lanus.digital' || cleanUrl == 'lanus.digital') {
      cleanUrl = 'https://www.lanus.digital';
    }
    await prefs.setString(serverUrlKey, cleanUrl);
  }

  /// Sincroniza un viaje hacia la base de datos de Lanús GIS vía HTTP POST
  static Future<SyncResult> syncTrip({
    required AppDatabase db,
    required TripEntry trip,
    required LineEntry line,
    required BranchEntry branch,
    required List<TrackPointEntry> trackPoints,
    required List<StopEntry> stops,
    required List<IncidentEntry> incidents,
  }) async {
    final baseUrl = await getServerUrl();
    try {
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
      ).timeout(const Duration(seconds: 15));

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
        return SyncResult(
          success: true,
          statusCode: response.statusCode,
          serverUrl: baseUrl,
          message: 'Viaje sincronizado exitosamente.',
        );
      } else {
        await (db.update(db.trips)..where((t) => t.id.equals(trip.id))).write(
          const TripsCompanion(syncStatus: Value('FAILED')),
        );
        return SyncResult(
          success: false,
          statusCode: response.statusCode,
          serverUrl: baseUrl,
          message: 'Servidor respondió con código ${response.statusCode}: ${response.reasonPhrase ?? response.body}',
        );
      }
    } catch (e) {
      await (db.update(db.trips)..where((t) => t.id.equals(trip.id))).write(
        const TripsCompanion(syncStatus: Value('FAILED')),
      );
      return SyncResult(
        success: false,
        serverUrl: baseUrl,
        message: 'No se pudo conectar a $baseUrl ($e)',
      );
    }
  }

  /// Procesa e importa un lote de líneas y trazas oficiales de Lanús Digital en una única transacción SQLite ultra rápida
  static Future<int> importCatalogData(AppDatabase db, List<dynamic> data) async {
    if (data.isEmpty) return 0;
    int updatedCount = 0;

    await db.transaction(() async {
      // 1. Pre-cargar caché en memoria para evitar cientos de SELECTs individuales
      final existingLines = await db.select(db.lines).get();
      final lineByNumber = <String, LineEntry>{
        for (final l in existingLines) TransportUtils.normalizeLineNumber(l.number): l,
      };

      final existingBranches = await db.select(db.branches).get();
      final branchByKey = <String, BranchEntry>{
        for (final b in existingBranches) '${b.lineId}_${b.name.trim().toLowerCase()}': b,
      };

      final existingRoutes = await db.select(db.referenceRoutes).get();
      final routeByKey = <String, ReferenceRouteEntry>{
        for (final r in existingRoutes) '${r.lineId}_${r.branchId}_${r.direction.toUpperCase()}': r,
      };

      for (final item in data) {
        if (item is! Map) continue;
        final rawNumero = (item['numero'] ?? item['linea'] ?? item['nombre'] ?? '').toString();
        final numero = TransportUtils.normalizeLineNumber(rawNumero);
        if (numero.isEmpty) continue;

        final isMunicipal = TransportUtils.isMunicipalLine(numero);
        final lineName = item['nombre']?.toString() ?? 'Línea $numero';

        // Gestión de Línea
        var line = lineByNumber[numero];
        int lineId;
        if (line == null) {
          lineId = await db.into(db.lines).insert(
                LinesCompanion.insert(
                  number: numero,
                  name: lineName,
                  active: Value(isMunicipal),
                ),
              );
          line = LineEntry(
            id: lineId,
            number: numero,
            name: lineName,
            active: isMunicipal,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          lineByNumber[numero] = line;
          updatedCount++;
        } else {
          lineId = line.id;
          // Si el estado o nombre cambiaron, actualizar
          if (line.active != isMunicipal || line.name != lineName) {
            await (db.update(db.lines)..where((l) => l.id.equals(lineId))).write(
              LinesCompanion(
                name: Value(lineName),
                active: Value(isMunicipal),
              ),
            );
            lineByNumber[numero] = LineEntry(
              id: lineId,
              number: numero,
              name: lineName,
              active: isMunicipal,
              createdAt: line.createdAt,
              updatedAt: DateTime.now(),
            );
          }
        }

        // Gestión de Ramal
        final rawRamal = (item['subcategoria'] ?? item['ramal'] ?? item['nombre_ramal'] ?? 'Principal').toString().trim();
        final ramalKey = '${lineId}_${rawRamal.toLowerCase()}';
        var branch = branchByKey[ramalKey];
        int branchId;
        final desc = item['descripcion']?.toString() ?? item['desc']?.toString();

        if (branch == null) {
          branchId = await db.into(db.branches).insert(
                BranchesCompanion.insert(
                  lineId: lineId,
                  name: rawRamal,
                  description: Value(desc),
                ),
              );
          branch = BranchEntry(
            id: branchId,
            lineId: lineId,
            name: rawRamal,
            description: desc,
            active: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          branchByKey[ramalKey] = branch;
          updatedCount++;
        } else {
          branchId = branch.id;
          if (desc != null && branch.description != desc) {
            await (db.update(db.branches)..where((b) => b.id.equals(branchId))).write(
              BranchesCompanion(description: Value(desc)),
            );
          }
        }

        // Gestión de Traza GeoJSON en ReferenceRoutes
        final datosGeo = item['datosGeo'] ?? item['datos_geo'] ?? item['geoData'] ?? item['geojson'] ?? item['geo_json'];
        if (datosGeo != null) {
          final rawGeoString = datosGeo is String ? datosGeo : jsonEncode(datosGeo);
          if (rawGeoString.trim().length > 20 && rawGeoString.trim() != '{}') {
            final sentido = (item['sentido'] ?? 'IDA').toString().toUpperCase().trim();
            final routeKey = '${lineId}_${branchId}_$sentido';
            final routeName = 'Línea $numero - $rawRamal ($sentido)';

            final existingRef = routeByKey[routeKey];
            if (existingRef == null) {
              final newId = await db.into(db.referenceRoutes).insert(
                    ReferenceRoutesCompanion.insert(
                      lineId: lineId,
                      branchId: branchId,
                      direction: sentido,
                      name: routeName,
                      format: 'GEOJSON',
                      geoJsonData: rawGeoString,
                    ),
                  );
              routeByKey[routeKey] = ReferenceRouteEntry(
                id: newId,
                lineId: lineId,
                branchId: branchId,
                direction: sentido,
                name: routeName,
                format: 'GEOJSON',
                geoJsonData: rawGeoString,
                createdAt: DateTime.now(),
              );
              updatedCount++;
            } else if (existingRef.geoJsonData != rawGeoString) {
              await (db.update(db.referenceRoutes)..where((r) => r.id.equals(existingRef.id))).write(
                ReferenceRoutesCompanion(
                  geoJsonData: Value(rawGeoString),
                  name: Value(routeName),
                ),
              );
              updatedCount++;
            }
          }
        }
      }
    });

    await db.cleanupAndMergeDuplicateLines();
    return updatedCount;
  }

  /// Carga de manera instantánea el paquete preinstalado de recorridos oficiales de Lanús Digital
  static Future<int> seedFromBundledAsset(AppDatabase db) async {
    try {
      final existingRoutes = await (db.select(db.referenceRoutes)).get();
      if (existingRoutes.length >= 200) {
        return existingRoutes.length;
      }

      final jsonString = await rootBundle.loadString('assets/data/lanus_official_routes.json');
      final dynamic decoded = jsonDecode(jsonString);
      final List<dynamic> data = decoded is List ? decoded : (decoded['lineas'] ?? decoded['data'] ?? []);
      return await importCatalogData(db, data);
    } catch (_) {
      return 0;
    }
  }

  /// Descarga y actualiza el catálogo oficial de líneas y ramales de Lanús Digital
  static Future<int> fetchOfficialLines(AppDatabase db) async {
    // 1. Asegura que el catálogo base municipal esté cargado en la base de datos local
    await db.seedInitialTransportData();

    // 2. Cargar primero el catálogo preempaquetado si aún no se importaron los recorridos
    await seedFromBundledAsset(db);

    int updatedCount = 0;
    try {
      final baseUrl = await getServerUrl();
      final endpoint = Uri.parse('$baseUrl${LanusCredentials.linesCatalogPath}');
      final response = await http.get(endpoint).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['lineas'] ?? decoded['data'] ?? []);
        updatedCount = await importCatalogData(db, data);
      }
    } catch (_) {}

    // 3. Descargar relevamientos adicionales realizados en Lanús Digital por otros usuarios
    await fetchBitacoraGpsSurveys(db);

    final totalActiveLines = await (db.select(db.lines)..where((l) => l.active.equals(true))).get();
    return updatedCount > 0 ? updatedCount : totalActiveLines.length;
  }

  /// Descarga los relevamientos y trazas de campo realizados con Bitácora GPS (/api/bitacora-gps)
  static Future<int> fetchBitacoraGpsSurveys(AppDatabase db) async {
    int importedCount = 0;
    try {
      final baseUrl = await getServerUrl();
      final endpoint = Uri.parse('$baseUrl${LanusCredentials.syncTripsPath}');
      final response = await http.get(
        endpoint,
        headers: {
          'X-App-Client': LanusCredentials.clientIdentifier,
          'X-API-Key': LanusCredentials.internalApiKey,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> items = decoded is List
            ? decoded
            : (decoded['items'] ?? decoded['relevamientos'] ?? decoded['trips'] ?? []);

        for (final item in items) {
          final rawNumero = (item['lineaNumero'] ?? item['linea'] ?? item['numero'] ?? '').toString();
          final lineaNumero = TransportUtils.normalizeLineNumber(rawNumero);
          final ramal = (item['ramal'] ?? item['subcategoria'] ?? 'Principal').toString();
          final sentido = (item['sentido'] ?? 'IDA').toString().toUpperCase();
          final datosGeo = item['datosGeo'] ?? item['datos_geo'] ?? item['geoData'] ?? item['geojson'] ?? item['geo_json'] ?? item['recorrido'] ?? item['trazas'] ?? item['route_data'];

          if (lineaNumero.isEmpty || datosGeo == null) continue;

          final rawGeoString = datosGeo is String ? datosGeo : jsonEncode(datosGeo);
          if (rawGeoString.trim().isEmpty || rawGeoString == '{}') continue;

          // Asegura que exista la Línea
          final existingLine = (await (db.select(db.lines)..where((l) => l.number.equals(lineaNumero))).get()).firstOrNull;
          int lineId;
          if (existingLine == null) {
            lineId = await db.into(db.lines).insert(
                  LinesCompanion.insert(
                    number: lineaNumero,
                    name: 'Línea $lineaNumero',
                    active: Value(TransportUtils.isMunicipalLine(lineaNumero)),
                  ),
                );
          } else {
            lineId = existingLine.id;
          }

          // Asegura que exista el Ramal
          final existingBranch = (await (db.select(db.branches)
                ..where((b) => b.lineId.equals(lineId) & b.name.equals(ramal)))
              .get()).firstOrNull;
          int branchId;
          if (existingBranch == null) {
            branchId = await db.into(db.branches).insert(
                  BranchesCompanion.insert(
                    lineId: lineId,
                    name: ramal,
                  ),
                );
          } else {
            branchId = existingBranch.id;
          }

          // Guarda o actualiza la traza en ReferenceRoutes
          final existingRef = (await (db.select(db.referenceRoutes)
                ..where((r) =>
                    r.lineId.equals(lineId) &
                    r.branchId.equals(branchId) &
                    r.direction.equals(sentido)))
              .get()).firstOrNull;

          final routeName = 'Línea $lineaNumero - $ramal ($sentido)';

          if (existingRef == null) {
            await db.into(db.referenceRoutes).insert(
                  ReferenceRoutesCompanion.insert(
                    lineId: lineId,
                    branchId: branchId,
                    direction: sentido,
                    name: routeName,
                    format: 'GEOJSON',
                    geoJsonData: rawGeoString,
                  ),
                );
            importedCount++;
          } else {
            await (db.update(db.referenceRoutes)..where((r) => r.id.equals(existingRef.id))).write(
              ReferenceRoutesCompanion(
                geoJsonData: Value(rawGeoString),
                name: Value(routeName),
              ),
            );
            importedCount++;
          }
        }
      }
    } catch (_) {}
    await db.cleanupAndMergeDuplicateLines();
    return importedCount;
  }
}
