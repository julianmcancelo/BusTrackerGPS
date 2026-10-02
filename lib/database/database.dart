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

import 'tables/frequency_tables.dart';
import '../core/utils/transport_utils.dart';

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
    FrequencySessions,
    FrequencyRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'bitacora_gps_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            // ignore: avoid_print
            print('Drift Web: ${result.chosenImplementation}, missing: ${result.missingFeatures}');
          }
        },
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
          await customStatement('CREATE INDEX idx_freq_records_session_id ON frequency_records (session_id);');
          await customStatement('CREATE INDEX idx_freq_records_observed_at ON frequency_records (observed_at);');

          await seedInitialTransportData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(trips, trips.syncStatus);
            await m.addColumn(trips, trips.syncedAt);
            await m.addColumn(trips, trips.remoteId);
          }
          if (from < 3) {
            await m.createTable(frequencySessions);
            await m.createTable(frequencyRecords);
            await customStatement('CREATE INDEX IF NOT EXISTS idx_freq_records_session_id ON frequency_records (session_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_freq_records_observed_at ON frequency_records (observed_at);');
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

      final existing = (await (select(lines)..where((t) => t.number.equals(number))).get()).firstOrNull;

      int lineId;
      if (existing == null) {
        lineId = await into(lines).insert(
          LinesCompanion.insert(
            number: number,
            name: name,
            active: const Value(true),
          ),
        );
      } else {
        lineId = existing.id;
        await (update(lines)..where((l) => l.id.equals(lineId))).write(
          const LinesCompanion(active: Value(true)),
        );
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

    // Desactiva para el relevamiento e inspección de campo todas las líneas no municipales
    await (update(lines)..where((l) => l.number.isNotIn(TransportUtils.municipalLineNumbers.toList()))).write(
      const LinesCompanion(active: Value(false)),
    );

    // Asegura que las 7 comunales municipales de Lanús queden activas
    await (update(lines)..where((l) => l.number.isIn(TransportUtils.municipalLineNumbers.toList()))).write(
      const LinesCompanion(active: Value(true)),
    );

    // Unifica y limpia de raíz posibles duplicados existentes
    await cleanupAndMergeDuplicateLines();
  }

  /// Limpia y fusiona de manera idempotente cualquier línea o ramal duplicado en la base de datos local.
  Future<void> cleanupAndMergeDuplicateLines() async {
    final allLines = await select(lines).get();
    if (allLines.isEmpty) return;

    final Map<String, List<LineEntry>> grouped = {};
    for (final line in allLines) {
      final canon = TransportUtils.normalizeLineNumber(line.number);
      if (canon.isEmpty) continue;
      grouped.putIfAbsent(canon, () => []).add(line);
    }

    for (final entry in grouped.entries) {
      final canonNumber = entry.key;
      final lineList = entry.value;

      if (lineList.length <= 1) {
        if (lineList.first.number != canonNumber) {
          await (update(lines)..where((l) => l.id.equals(lineList.first.id))).write(
            LinesCompanion(number: Value(canonNumber)),
          );
        }
        continue;
      }

      // Ordena: favorece la que ya tiene el número canónico y nombre más largo
      lineList.sort((a, b) {
        if (a.number == canonNumber && b.number != canonNumber) return -1;
        if (b.number == canonNumber && a.number != canonNumber) return 1;
        return b.name.length.compareTo(a.name.length);
      });

      final master = lineList.first;
      if (master.number != canonNumber) {
        await (update(lines)..where((l) => l.id.equals(master.id))).write(
          LinesCompanion(number: Value(canonNumber)),
        );
      }

      final masterBranches = await (select(branches)..where((b) => b.lineId.equals(master.id))).get();

      for (int i = 1; i < lineList.length; i++) {
        final dup = lineList[i];

        // 1. Reasignar o fusionar ramales
        final dupBranches = await (select(branches)..where((b) => b.lineId.equals(dup.id))).get();
        for (final dupBranch in dupBranches) {
          final dupBranchName = dupBranch.name.trim().toLowerCase();
          final matchingMasterBranch = masterBranches.where((mb) => mb.name.trim().toLowerCase() == dupBranchName).firstOrNull;

          if (matchingMasterBranch != null) {
            await (update(trips)..where((t) => t.branchId.equals(dupBranch.id))).write(
              TripsCompanion(lineId: Value(master.id), branchId: Value(matchingMasterBranch.id)),
            );
            await (update(referenceRoutes)..where((r) => r.branchId.equals(dupBranch.id))).write(
              ReferenceRoutesCompanion(lineId: Value(master.id), branchId: Value(matchingMasterBranch.id)),
            );
            await (update(frequencyRecords)..where((f) => f.branchId.equals(dupBranch.id))).write(
              FrequencyRecordsCompanion(lineId: Value(master.id), branchId: Value(matchingMasterBranch.id)),
            );
            await (delete(branches)..where((b) => b.id.equals(dupBranch.id))).go();
          } else {
            await (update(branches)..where((b) => b.id.equals(dupBranch.id))).write(
              BranchesCompanion(lineId: Value(master.id)),
            );
            masterBranches.add(dupBranch);
          }
        }

        // 2. Reasignar cualquier viaje, traza o registro de frecuencia restante
        await (update(trips)..where((t) => t.lineId.equals(dup.id))).write(
          TripsCompanion(lineId: Value(master.id)),
        );
        await (update(referenceRoutes)..where((r) => r.lineId.equals(dup.id))).write(
          ReferenceRoutesCompanion(lineId: Value(master.id)),
        );
        await (update(frequencyRecords)..where((f) => f.lineId.equals(dup.id))).write(
          FrequencyRecordsCompanion(lineId: Value(master.id)),
        );

        // 3. Eliminar la línea duplicada
        await (delete(lines)..where((l) => l.id.equals(dup.id))).go();
      }
    }
  }
}
