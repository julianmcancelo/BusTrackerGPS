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
  int get schemaVersion => 1;

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

          await _seedInitialTransportData();
        },
      );

  Future<void> _seedInitialTransportData() async {
    final line526Id = await into(lines).insert(
      LinesCompanion.insert(
        number: '526',
        name: 'Línea 526 (Lanús - Terminal)',
      ),
    );

    await into(branches).insert(
      BranchesCompanion.insert(
        lineId: line526Id,
        name: 'Principal',
        description: const Value('Recorrido principal Lanús Centro - Terminal'),
      ),
    );
    await into(branches).insert(
      BranchesCompanion.insert(
        lineId: line526Id,
        name: 'Hospital',
        description: const Value('Ramal Hospital Evita'),
      ),
    );
    await into(branches).insert(
      BranchesCompanion.insert(
        lineId: line526Id,
        name: 'Terminal',
        description: const Value('Ramal directo a Terminal'),
      ),
    );

    final line524Id = await into(lines).insert(
      LinesCompanion.insert(
        number: '524',
        name: 'Línea 524 (Monte Chingolo - Est. Lanús)',
      ),
    );

    await into(branches).insert(
      BranchesCompanion.insert(
        lineId: line524Id,
        name: 'Principal',
        description: const Value('Monte Chingolo por Lynch'),
      ),
    );

    final line500Id = await into(lines).insert(
      LinesCompanion.insert(
        number: '500',
        name: 'Línea 500 (Lanús - Est. Escalada)',
      ),
    );

    await into(branches).insert(
      BranchesCompanion.insert(
        lineId: line500Id,
        name: 'Est. Escalada',
        description: const Value('Ramal Remedios de Escalada'),
      ),
    );

    final line283Id = await into(lines).insert(
      LinesCompanion.insert(
        number: '283',
        name: 'Línea 283 (Lanús - Pompeya)',
      ),
    );

    await into(branches).insert(
      BranchesCompanion.insert(
        lineId: line283Id,
        name: 'Pompeya',
        description: const Value('Ramal Puente Alsina / Pompeya'),
      ),
    );
  }
}
