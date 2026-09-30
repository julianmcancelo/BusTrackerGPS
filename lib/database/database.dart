import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/lines_table.dart';
import 'tables/branches_table.dart';
import 'tables/trips_table.dart';
import 'tables/track_points_table.dart';
import 'tables/stops_table.dart';
import 'tables/incidents_table.dart';
import 'tables/attachments_table.dart';
import 'tables/reference_routes_table.dart';
import 'tables/offline_map_regions_table.dart';
import 'tables/settings_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Lines,
    Branches,
    Trips,
    TrackPoints,
    Stops,
    Incidents,
    Attachments,
    ReferenceRoutes,
    OfflineMapRegions,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'bitacora_gps_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();

          await customStatement('CREATE INDEX idx_track_points_trip_id ON track_points (trip_id);');
          await customStatement('CREATE INDEX idx_track_points_timestamp ON track_points (timestamp);');
          await customStatement('CREATE INDEX idx_stops_trip_id ON stops (trip_id);');
          await customStatement('CREATE INDEX idx_incidents_trip_id ON incidents (trip_id);');
          await customStatement('CREATE INDEX idx_trips_started_at ON trips (started_at);');
          await customStatement('CREATE INDEX idx_trips_line_id ON trips (line_id);');

          await seedInitialTransportData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(trips, trips.syncStatus);
            await m.addColumn(trips, trips.syncedAt);
            await m.addColumn(trips, trips.remoteId);
          }
        },
      );

  Future<void> seedInitialTransportData() async {
    final defaultLines = [
      {
        'number': '520',
        'name': 'Línea 520 (MOASA - Lanús / Villa Caraza)',
        'branches': [
          {'name': 'Ramal B', 'desc': 'Estación Lanús - Villa Caraza'},
          {'name': 'Ramal B2', 'desc': 'Hospital Interzonal (Evita) - Villa Caraza'},
          {'name': 'Ramal C', 'desc': 'Estación Lanús - Villa Caraza (por Barrio Eva Perón)'},
          {'name': 'Ramal D', 'desc': 'Ex Línea 529 (Conexiones Lanús Oeste)'},
        ]
      },
      {
        'number': '521',
        'name': 'Línea 521 (MOESA - Lanús / Villa Obrera)',
        'branches': [
          {'name': 'Principal', 'desc': 'Estación Lanús - Villa Obrera (por Bv. Martín Rodríguez y Eva Perón)'},
        ]
      },
      {
        'number': '522',
        'name': 'Línea 522 (El Urbano - Lanús / Monte Chingolo)',
        'branches': [
          {'name': 'Principal', 'desc': 'Estación Lanús - Cnel. Lynch y Caaguazú (Monte Chingolo)'},
        ]
      },
      {
        'number': '523',
        'name': 'Línea 523 (Cía. Andrade - Lanús / Escalada)',
        'branches': [
          {'name': 'Principal (Unión Comunal)', 'desc': 'Estación Lanús - Estación Remedios de Escalada'},
        ]
      },
      {
        'number': '524',
        'name': 'Línea 524 (5 de Agosto - Lanús / Monte Chingolo)',
        'branches': [
          {'name': 'Principal', 'desc': 'Estación Lanús - Charcas y Cno. Gral. Belgrano (por Centenario)'},
        ]
      },
      {
        'number': '526',
        'name': 'Línea 526 (MOESA - Lanús / Villa Ofelia)',
        'branches': [
          {'name': 'Principal', 'desc': 'Estación Lanús - Villa Ofelia (por H. Guidi, 9 de Julio y Kloosterman)'},
        ]
      },
      {
        'number': '527',
        'name': 'Línea 527 (El Urbano - Lanús / Monte Chingolo)',
        'branches': [
          {'name': 'Ramal B (Corina por Cadorna)', 'desc': 'Estación Lanús - Cno. Gral. Belgrano y Av. Fabián Onsari'},
          {'name': 'Ramal C (Hospital Evita)', 'desc': 'Estación Lanús - Hospital Evita / Roma y Lynch'},
          {'name': 'Ramal C (ex 522)', 'desc': 'Estación Lanús - Estación Monte Chingolo - Cnel. Lynch'},
        ]
      },
    ];

    for (final lineData in defaultLines) {
      final number = lineData['number'] as String;
      final name = lineData['name'] as String;
      final branchesList = lineData['branches'] as List<Map<String, String>>;

      final existing = await (select(lines)..where((t) => t.number.equals(number))).getSingleOrNull();

      int lineId;
      if (existing == null) {
        lineId = await into(lines).insert(
          LinesCompanion.insert(
            number: number,
            name: name,
          ),
        );
      } else {
        lineId = existing.id;
      }

      final existingBranches = await (select(branches)..where((t) => t.lineId.equals(lineId))).get();
      for (final bData in branchesList) {
        final bName = bData['name']!;
        final bDesc = bData['desc'];
        final bExists = existingBranches.any((b) => b.name == bName);
        if (!bExists) {
          await into(branches).insert(
            BranchesCompanion.insert(
              lineId: lineId,
              name: bName,
              description: Value(bDesc),
            ),
          );
        }
      }
    }
  }
}
