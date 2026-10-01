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
      {'number': '9', 'name': 'Línea 9 (Gral. Tomás Guido)', 'branches': [{'name': 'Ramal 1', 'desc': 'Retiro - Villa Caraza'}, {'name': 'Ramal 2', 'desc': 'Retiro - Villa Caraza'}, {'name': 'Ramal Expreso', 'desc': 'Retiro - Villa Caraza'}]},
      {'number': '10', 'name': 'Línea 10 (Línea 10 S.A.)', 'branches': [{'name': 'Principal', 'desc': 'Palermo - Wilde (por Est. Lanús)'}]},
      {'number': '15', 'name': 'Línea 15 (Transportes Sur-Nor)', 'branches': [{'name': 'Principal', 'desc': 'Benavídez - Puente Uriburu'}, {'name': 'Semirápido', 'desc': 'Benavídez - Puente Uriburu'}]},
      {'number': '20', 'name': 'Línea 20 (Micro Ómnibus Larrazábal)', 'branches': [{'name': 'Ramal 1', 'desc': 'Retiro - Lanús Oeste'}, {'name': 'Ramal 3', 'desc': 'Retiro - Lanús Oeste'}]},
      {'number': '28', 'name': 'Línea 28 (DOTA)', 'branches': [{'name': 'Principal', 'desc': 'Retiro - Pte. La Noria - Liniers - C. Universitaria'}]},
      {'number': '31', 'name': 'Línea 31 (Rocaraza S.A.)', 'branches': [{'name': 'Ramal Calle 11', 'desc': 'Plaza Miserere - Villa Caraza'}, {'name': 'Ramal Calle 21', 'desc': 'Plaza Miserere - Villa Caraza'}]},
      {'number': '32', 'name': 'Línea 32 (El Puente S.A.T.)', 'branches': [{'name': 'Ramal P', 'desc': 'Once - Lanús / Monte Chingolo'}]},
      {'number': '33', 'name': 'Línea 33 (Transportes San Roch)', 'branches': [{'name': 'Ramal Roja', 'desc': 'C. Universitaria - Remedios de Escalada'}, {'name': 'Ramal C', 'desc': 'C. Universitaria - Monte Chingolo'}, {'name': 'Ramal M', 'desc': 'Retiro - Remedios de Escalada'}]},
      {'number': '37', 'name': 'Línea 37 (4 de Septiembre)', 'branches': [{'name': 'Ramal 1', 'desc': 'C. Universitaria - Lanús'}, {'name': 'Ramal 3', 'desc': 'C. Universitaria - Lanús por Congreso'}, {'name': 'Ramal 4', 'desc': 'Palermo - Lanús'}]},
      {'number': '45', 'name': 'Línea 45 (Micro Ómnibus 45)', 'branches': [{'name': 'Principal', 'desc': 'C. Universitaria - Remedios de Escalada'}, {'name': 'Semirápido', 'desc': 'C. Universitaria - Remedios de Escalada por Autopista'}]},
      {'number': '51', 'name': 'Línea 51 (Empresa San Vicente)', 'branches': [{'name': 'Principal', 'desc': 'Constitución - Cañuelas / Brandsen (por Lanús)'}]},
      {'number': '54', 'name': 'Línea 54 (Autobuses Buenos Aires)', 'branches': [{'name': 'Principal', 'desc': 'Puente La Noria - Estación Lanús'}]},
      {'number': '70', 'name': 'Línea 70 (Transportes 270)', 'branches': [{'name': 'Principal', 'desc': 'Retiro - Valentín Alsina'}]},
      {'number': '74', 'name': 'Línea 74 (Empresa San Vicente)', 'branches': [{'name': 'Principal', 'desc': 'Correo Central - Burzaco (por Lanús)'}]},
      {'number': '75', 'name': 'Línea 75 (El Puente S.A.T.)', 'branches': [{'name': 'Principal', 'desc': 'Retiro - Lanús Oeste'}]},
      {'number': '79', 'name': 'Línea 79 (Empresa San Vicente)', 'branches': [{'name': 'Principal', 'desc': 'Constitución - San Vicente (por Lanús)'}]},
      {'number': '85', 'name': 'Línea 85 (SAES)', 'branches': [{'name': 'Ramal A', 'desc': 'C. Universitaria - Balneario Quilmes'}, {'name': 'Ramal G', 'desc': 'C. Universitaria - Quilmes'}, {'name': 'Ramal I', 'desc': 'C. Universitaria - Bernal'}]},
      {'number': '100', 'name': 'Línea 100 (TARSA)', 'branches': [{'name': 'Ramal 1', 'desc': 'Retiro - Lanús por Pavón'}, {'name': 'Ramal 3', 'desc': 'Retiro - Lanús por Güemes'}]},
      {'number': '119', 'name': 'Línea 119 (Empresa San Vicente)', 'branches': [{'name': 'Principal', 'desc': 'Chacarita - Lanús'}]},
      {'number': '128', 'name': 'Línea 128 (El Puente S.A.T.)', 'branches': [{'name': 'Principal', 'desc': 'Palermo - Valentín Alsina'}]},
      {'number': '154', 'name': 'Línea 154 (Micro Ómnibus 45)', 'branches': [{'name': 'Principal', 'desc': 'Constitución - Lanús'}]},
      {'number': '158', 'name': 'Línea 158 (El Puente S.A.T.)', 'branches': [{'name': 'Principal', 'desc': 'Nueva Pompeya - Lanús'}]},
      {'number': '160', 'name': 'Línea 160 (Micro Ómnibus Sur)', 'branches': [{'name': 'Ramal A', 'desc': 'C. Universitaria - Claypole'}, {'name': 'Ramal G', 'desc': 'C. Universitaria - Ministro Rivadavia'}, {'name': 'Ramal R', 'desc': 'Palermo - Claypole'}]},
      {'number': '164', 'name': 'Línea 164 (Gral. Tomás Guido)', 'branches': [{'name': 'Ramal A', 'desc': 'Plaza Miserere - Monte Grande'}, {'name': 'Ramal B', 'desc': 'Plaza Miserere - Burzaco'}, {'name': 'Ramal C', 'desc': 'Pompeya - Monte Grande'}]},
      {'number': '177', 'name': 'Línea 177 (Empresa San Vicente)', 'branches': [{'name': 'Ramal 1', 'desc': 'Nueva Pompeya - Burzaco (por Lanús)'}]},
      {'number': '178', 'name': 'Línea 178 (La Colorada)', 'branches': [{'name': 'Ramal B', 'desc': 'Nueva Pompeya - Florencio Varela'}, {'name': 'Ramal C Verde', 'desc': 'Nueva Pompeya - Zeballos'}, {'name': 'Ramal C Rojo', 'desc': 'Nueva Pompeya - Alpargatas'}, {'name': 'Ramal G', 'desc': 'Nueva Pompeya - Varela'}]},
      {'number': '179', 'name': 'Línea 179 (El Trébol)', 'branches': [{'name': 'Ramal 1', 'desc': 'Nueva Pompeya - Fiorito - Lanús'}, {'name': 'Ramal 2', 'desc': 'Nueva Pompeya - Santa Marta - Lanús'}, {'name': 'Ramal 3', 'desc': 'Nueva Pompeya - San José - Lanús'}]},
      {'number': '188', 'name': 'Línea 188 (Micro Ómnibus Larrazábal)', 'branches': [{'name': 'Ramal 1', 'desc': 'Plaza Italia - Cruce Lomas'}, {'name': 'Ramal 2', 'desc': 'Plaza Italia - Santa Catalina'}, {'name': 'Ramal 3', 'desc': 'Palermo - Villa Fiorito'}]},
      {'number': '239', 'name': 'Línea 239 (Expreso Villa Galicia)', 'branches': [{'name': 'Ramal P', 'desc': 'Estación Lanús - Villa Galicia / Banfield'}]},
      {'number': '247', 'name': 'Línea 247 (Expreso Nueve de Julio)', 'branches': [{'name': 'Ramal 2', 'desc': 'Villa Fiorito - San Francisco Solano'}, {'name': 'Ramal 5', 'desc': 'Puente Uriburu - Claypole'}, {'name': 'Ramal 7', 'desc': 'Lanús - Pasco'}]},
      {'number': '263', 'name': 'Línea 263 (Empresa San Vicente)', 'branches': [{'name': 'Ramal M', 'desc': 'Estación Lanús - Burzaco'}, {'name': 'Ramal R', 'desc': 'Estación Lanús - Claypole'}]},
      {'number': '266', 'name': 'Línea 266 (Expreso Villa Galicia)', 'branches': [{'name': 'Ramal 1', 'desc': 'Estación Lanús - Lomas de Zamora'}, {'name': 'Ramal 2', 'desc': 'Estación Lanús - San José'}]},
      {'number': '271', 'name': 'Línea 271 (Compañía La Paz)', 'branches': [{'name': 'Principal', 'desc': 'Avellaneda - Burzaco (por Lanús)'}]},
      {'number': '277', 'name': 'Línea 277 (Autobuses Buenos Aires)', 'branches': [{'name': 'Principal', 'desc': 'Avellaneda - Universidad de Lomas de Zamora (por Lanús)'}]},
      {'number': '283', 'name': 'Línea 283 (Cía. Andrade)', 'branches': [{'name': 'Ramal B1', 'desc': 'Estación Lanús - Puente La Noria'}, {'name': 'Ramal B2', 'desc': 'Estación Lanús - Santa Catalina'}, {'name': 'Ramal B3', 'desc': 'Estación Lanús - Lomas de Zamora'}]},
      {'number': '293', 'name': 'Línea 293 (Expreso El Triángulo)', 'branches': [{'name': 'Ramal B', 'desc': 'Avellaneda - San Francisco Solano (por Lanús)'}]},
      {'number': '295', 'name': 'Línea 295 (Micro Ómnibus O\'Gorman)', 'branches': [{'name': 'Ramal 1', 'desc': 'Estación Lanús - Wilde'}, {'name': 'Ramal 2', 'desc': 'Estación Lanús - Avellaneda'}, {'name': 'Ramal 4', 'desc': 'Estación Lanús - Bernal'}, {'name': 'Ramal 5', 'desc': 'Estación Lanús - Crucecita'}]},
      {'number': '299', 'name': 'Línea 299 (Expreso Villa Galicia)', 'branches': [{'name': 'Ramal C', 'desc': 'Estación Lanús - Banfield'}, {'name': 'Ramal M', 'desc': 'Estación Lanús - Monte Chingolo'}, {'name': 'Ramal SJ', 'desc': 'Estación Lanús - San José'}]},
      {'number': '318', 'name': 'Línea 318 (Micro Ómnibus Mitre)', 'branches': [{'name': 'Ramal A', 'desc': 'Puente La Noria - Claypole (por Lanús)'}, {'name': 'Ramal B', 'desc': 'Puente La Noria - Adrogué'}, {'name': 'Ramal M', 'desc': 'Lanús - Llavallol'}]},
      {'number': '323', 'name': 'Línea 323 (Expreso Villa Galicia)', 'branches': [{'name': 'Principal', 'desc': 'Estación Lanús - San José'}]},
      {'number': '338', 'name': 'Línea 338 (TALP - Costera Criolla)', 'branches': [{'name': 'Ramal P', 'desc': 'La Plata - San Isidro (por Cruce Lomas / Lanús)'}]},
      {'number': '373', 'name': 'Línea 373 (General Tomás Guido)', 'branches': [{'name': 'Ramal 1', 'desc': 'Isla Maciel - Wilde (por Lanús)'}, {'name': 'Ramal 2', 'desc': 'Isla Maciel - Avellaneda'}, {'name': 'Ramal 5', 'desc': 'Puente Pueyrredón - Lanús'}]},
      {'number': '405', 'name': 'Línea 405 (Micro Ómnibus Larrazábal)', 'branches': [{'name': 'Principal', 'desc': 'Puente La Noria - Estación Lanús'}]},
      {'number': '406', 'name': 'Línea 406 (Autobuses Buenos Aires)', 'branches': [{'name': 'Ramal LZ', 'desc': 'San Justo - Lomas de Zamora (por Lanús)'}, {'name': 'Ramal SJ', 'desc': 'Morón - Lanús'}]},
      {'number': '436', 'name': 'Línea 436 (Expreso Villa Galicia)', 'branches': [{'name': 'Principal', 'desc': 'Estación Lanús - San José'}]},
      {'number': '520', 'name': 'Línea 520 (MOASA - Lanús / Villa Caraza)', 'branches': [{'name': 'Ramal B', 'desc': 'Estación Lanús - Villa Caraza'}, {'name': 'Ramal B2', 'desc': 'Hospital Interzonal (Evita) - Villa Caraza'}, {'name': 'Ramal C', 'desc': 'Estación Lanús - Villa Caraza (por Barrio Eva Perón)'}]},
      {'number': '521', 'name': 'Línea 521 (MOESA - Lanús / Villa Obrera)', 'branches': [{'name': 'Principal', 'desc': 'Estación Lanús - Villa Obrera (por Bv. Martín Rodríguez y Eva Perón)'}]},
      {'number': '522', 'name': 'Línea 522 (El Urbano - Lanús / Monte Chingolo)', 'branches': [{'name': 'Principal', 'desc': 'Estación Lanús - Cnel. Lynch y Caaguazú (Monte Chingolo)'}]},
      {'number': '523', 'name': 'Línea 523 (Cía. Andrade - Lanús / Escalada)', 'branches': [{'name': 'Principal', 'desc': 'Estación Lanús - Estación Remedios de Escalada'}]},
      {'number': '524', 'name': 'Línea 524 (5 de Agosto - Lanús / Monte Chingolo)', 'branches': [{'name': 'Principal', 'desc': 'Estación Lanús - Charcas y Cno. Gral. Belgrano (por Centenario)'}]},
      {'number': '526', 'name': 'Línea 526 (MOESA - Lanús / Villa Ofelia)', 'branches': [{'name': 'Principal', 'desc': 'Estación Lanús - Villa Ofelia (por H. Guidi, 9 de Julio y Kloosterman)'}]},
      {'number': '527', 'name': 'Línea 527 (El Urbano - Lanús / Monte Chingolo)', 'branches': [{'name': 'Ramal B', 'desc': 'Estación Lanús - Cno. Gral. Belgrano y Av. Fabián Onsari'}, {'name': 'Ramal C', 'desc': 'Estación Lanús - Hospital Evita / Roma y Lynch'}, {'name': 'Ramal 522', 'desc': 'Estación Lanús - Estación Monte Chingolo - Cnel. Lynch'}]},
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
