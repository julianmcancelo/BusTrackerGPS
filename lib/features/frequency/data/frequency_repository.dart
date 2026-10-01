import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/database.dart';
import '../../../database/database_provider.dart';
import '../domain/frequency_models.dart';
import '../domain/frequency_analytics.dart';

final frequencyRepositoryProvider = Provider<FrequencyRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FrequencyRepository(db);
});

class FrequencyRepository {
  final AppDatabase _db;

  FrequencyRepository(this._db);

  /// Inicia una nueva sesión de aforo en punto de control
  Future<int> createSession({
    required String title,
    required String checkpointName,
    double? latitude,
    double? longitude,
    String? auditorName,
    List<int>? targetLineIds,
    String? notes,
  }) async {
    return _db.into(_db.frequencySessions).insert(
          FrequencySessionsCompanion.insert(
            title: title,
            checkpointName: checkpointName,
            latitude: Value(latitude),
            longitude: Value(longitude),
            auditorName: Value(auditorName),
            targetLineIds: Value(targetLineIds?.join(',')),
            notes: Value(notes),
            startedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Observa todas las sesiones ordenadas por fecha reciente
  Stream<List<FrequencySessionEntry>> watchSessions() {
    return (_db.select(_db.frequencySessions)
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .watch();
  }

  /// Obtiene una sesión por su ID
  Future<FrequencySessionEntry?> getSession(int id) async {
    return (_db.select(_db.frequencySessions)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Finaliza una sesión activa de aforo
  Future<void> finishSession(int sessionId, {String? notes}) async {
    final companion = FrequencySessionsCompanion(
      status: const Value('COMPLETED'),
      endedAt: Value(DateTime.now()),
      notes: notes != null ? Value(notes) : const Value.absent(),
    );
    await (_db.update(_db.frequencySessions)..where((s) => s.id.equals(sessionId))).write(companion);
  }

  /// Elimina una sesión y sus registros asociados
  Future<void> deleteSession(int sessionId) async {
    await (_db.delete(_db.frequencyRecords)..where((r) => r.sessionId.equals(sessionId))).go();
    await (_db.delete(_db.frequencySessions)..where((s) => s.id.equals(sessionId))).go();
  }

  /// Registra el paso de un colectivo con cálculo automático de headway
  Future<int> logBusPass({
    required int sessionId,
    required int lineId,
    required int branchId,
    required String direction,
    String? internalNumber,
    String? domain,
    int passengerLoad = 2,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final now = DateTime.now();

    // Buscar el paso previo más reciente para la misma línea, ramal y sentido
    final previousPass = await (_db.select(_db.frequencyRecords)
          ..where((r) =>
              r.sessionId.equals(sessionId) &
              r.lineId.equals(lineId) &
              r.branchId.equals(branchId) &
              r.direction.equals(direction))
          ..orderBy([(r) => OrderingTerm.desc(r.observedAt)])
          ..limit(1))
        .getSingleOrNull();

    int? headwaySeconds;
    bool isBunching = false;
    bool isDelayed = false;

    if (previousPass != null) {
      headwaySeconds = now.difference(previousPass.observedAt).inSeconds;
      if (headwaySeconds <= 120) {
        // Menos de 2 minutos = Acolchonamiento / Bunching
        isBunching = true;
      } else if (headwaySeconds >= 1200) {
        // Más de 20 minutos = Demora crítica
        isDelayed = true;
      }
    }

    return _db.into(_db.frequencyRecords).insert(
          FrequencyRecordsCompanion.insert(
            sessionId: sessionId,
            lineId: lineId,
            branchId: branchId,
            direction: direction,
            internalNumber: Value(internalNumber),
            domain: Value(domain),
            passengerLoad: Value(passengerLoad),
            observedAt: Value(now),
            headwaySeconds: Value(headwaySeconds),
            isBunching: Value(isBunching),
            isDelayed: Value(isDelayed),
            latitude: Value(latitude),
            longitude: Value(longitude),
            notes: Value(notes),
          ),
        );
  }

  /// Elimina un registro individual
  Future<void> deleteRecord(int recordId) async {
    await (_db.delete(_db.frequencyRecords)..where((r) => r.id.equals(recordId))).go();
  }

  /// Observa los registros de una sesión con detalles de Línea y Ramal
  Stream<List<FrequencyRecordWithDetails>> watchSessionRecords(int sessionId) {
    final query = _db.select(_db.frequencyRecords).join([
      innerJoin(_db.lines, _db.lines.id.equalsExp(_db.frequencyRecords.lineId)),
      innerJoin(_db.branches, _db.branches.id.equalsExp(_db.frequencyRecords.branchId)),
    ])
      ..where(_db.frequencyRecords.sessionId.equals(sessionId))
      ..orderBy([OrderingTerm.desc(_db.frequencyRecords.observedAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return FrequencyRecordWithDetails(
          record: row.readTable(_db.frequencyRecords),
          line: row.readTable(_db.lines),
          branch: row.readTable(_db.branches),
        );
      }).toList();
    });
  }

  /// Obtiene los registros de una sesión con detalles de Línea y Ramal
  Future<List<FrequencyRecordWithDetails>> getSessionRecords(int sessionId) async {
    final query = _db.select(_db.frequencyRecords).join([
      innerJoin(_db.lines, _db.lines.id.equalsExp(_db.frequencyRecords.lineId)),
      innerJoin(_db.branches, _db.branches.id.equalsExp(_db.frequencyRecords.branchId)),
    ])
      ..where(_db.frequencyRecords.sessionId.equals(sessionId))
      ..orderBy([OrderingTerm.asc(_db.frequencyRecords.observedAt)]);

    final rows = await query.get();
    return rows.map((row) {
      return FrequencyRecordWithDetails(
        record: row.readTable(_db.frequencyRecords),
        line: row.readTable(_db.lines),
        branch: row.readTable(_db.branches),
      );
    }).toList();
  }

  /// Genera el resumen consolidado de auditoría de la sesión
  Future<FrequencySessionAuditSummary?> getSessionAuditSummary(int sessionId) async {
    final session = await getSession(sessionId);
    if (session == null) return null;

    final records = await getSessionRecords(sessionId);
    return FrequencyAnalytics.computeSessionSummary(
      session: session,
      records: records,
    );
  }
}
