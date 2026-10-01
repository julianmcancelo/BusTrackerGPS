import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/database.dart';
import '../../../database/database_provider.dart';

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  return TransportRepository(ref.watch(databaseProvider));
});

class TransportRepository {
  final AppDatabase db;
  TransportRepository(this.db);

  Future<void> ensureDefaultTransportDataSeeded() async {
    await db.seedInitialTransportData();
  }

  Stream<List<LineEntry>> watchAllLines() {
    return (db.select(db.lines)
          ..where((t) => t.active.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.number)]))
        .watch()
        .map((lines) {
      final seen = <String>{};
      return lines.where((l) => seen.add(l.number.trim().toLowerCase())).toList();
    });
  }

  Future<List<LineEntry>> getAllLines() async {
    await ensureDefaultTransportDataSeeded();
    final allLines = await (db.select(db.lines)
          ..where((t) => t.active.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.number)]))
        .get();
    
    // Deduplicate by number
    final seen = <String>{};
    return allLines.where((l) => seen.add(l.number.trim().toLowerCase())).toList();
  }

  Stream<List<BranchEntry>> watchBranchesForLine(int lineId) {
    return (db.select(db.branches)
          ..where((t) => t.lineId.equals(lineId) & t.active.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((branches) {
      final seen = <String>{};
      return branches.where((b) => seen.add(b.name.trim().toLowerCase())).toList();
    });
  }

  Stream<List<BranchEntry>> watchBranchesForLineEntity(LineEntry line) {
    final query = db.select(db.branches).join([
      innerJoin(db.lines, db.lines.id.equalsExp(db.branches.lineId)),
    ])
      ..where(db.lines.number.equals(line.number) & db.branches.active.equals(true) & db.lines.active.equals(true))
      ..orderBy([OrderingTerm.asc(db.branches.name)]);

    return query.watch().map((rows) {
      final branches = rows.map((r) => r.readTable(db.branches)).toList();
      final seen = <String>{};
      return branches.where((b) => seen.add(b.name.trim().toLowerCase())).toList();
    });
  }

  Future<List<BranchEntry>> getBranchesForLine(int lineId) async {
    final allBranches = await (db.select(db.branches)
          ..where((t) => t.lineId.equals(lineId) & t.active.equals(true)))
        .get();
        
    final seen = <String>{};
    return allBranches.where((b) => seen.add(b.name.trim().toLowerCase())).toList();
  }

  Future<List<BranchEntry>> getBranchesForLineEntity(LineEntry line) async {
    final query = db.select(db.branches).join([
      innerJoin(db.lines, db.lines.id.equalsExp(db.branches.lineId)),
    ])
      ..where(db.lines.number.equals(line.number) & db.branches.active.equals(true) & db.lines.active.equals(true))
      ..orderBy([OrderingTerm.asc(db.branches.name)]);

    final rows = await query.get();
    final branches = rows.map((r) => r.readTable(db.branches)).toList();
    final seen = <String>{};
    return branches.where((b) => seen.add(b.name.trim().toLowerCase())).toList();
  }

  Future<int> addLine({required String number, required String name}) {
    return db.into(db.lines).insert(
          LinesCompanion.insert(
            number: number,
            name: name,
          ),
        );
  }

  Future<int> addBranch({
    required int lineId,
    required String name,
    String? description,
  }) {
    return db.into(db.branches).insert(
          BranchesCompanion.insert(
            lineId: lineId,
            name: name,
            description: Value(description),
          ),
        );
  }

  Future<void> updateLine({
    required int lineId,
    required String number,
    required String name,
  }) async {
    await (db.update(db.lines)..where((t) => t.id.equals(lineId))).write(
      LinesCompanion(
        number: Value(number),
        name: Value(name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateBranch({
    required int branchId,
    required String name,
    String? description,
  }) async {
    await (db.update(db.branches)..where((t) => t.id.equals(branchId))).write(
      BranchesCompanion(
        name: Value(name),
        description: Value(description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteLine(int lineId) async {
    await (db.update(db.lines)..where((t) => t.id.equals(lineId)))
        .write(const LinesCompanion(active: Value(false)));
  }

  Future<void> deleteBranch(int branchId) async {
    await (db.update(db.branches)..where((t) => t.id.equals(branchId)))
        .write(const BranchesCompanion(active: Value(false)));
  }

  Future<void> importConfigJson(String jsonString) async {
    final data = jsonDecode(jsonString);
    if (data is List) {
      for (final item in data) {
        final number = item['number']?.toString() ?? '';
        final name = item['name']?.toString() ?? 'Línea $number';
        final lineId = await addLine(number: number, name: name);

        final branches = item['branches'];
        if (branches is List) {
          for (final b in branches) {
            final bName = b['name']?.toString() ?? 'Principal';
            final bDesc = b['description']?.toString();
            await addBranch(lineId: lineId, name: bName, description: bDesc);
          }
        }
      }
    }
  }
}
