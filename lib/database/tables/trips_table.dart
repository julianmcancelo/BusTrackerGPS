import 'package:drift/drift.dart';
import 'lines_table.dart';
import 'branches_table.dart';

@DataClassName('TripEntry')
class Trips extends Table {
  TextColumn get id => text()();
  IntColumn get lineId => integer().references(Lines, #id)();
  IntColumn get branchId => integer().references(Branches, #id)();
  TextColumn get direction => text()(); // 'IDA' or 'VUELTA'
  TextColumn get internalNumber => text().nullable()();
  TextColumn get domain => text().nullable()();
  TextColumn get driverName => text().nullable()();
  TextColumn get notes => text().nullable()();

  TextColumn get status => text().withDefault(const Constant('ACTIVE'))(); // DRAFT, ACTIVE, PAUSED, FINISHED

  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();

  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  RealColumn get distanceMeters => real().withDefault(const Constant(0.0))();
  IntColumn get movingTimeMs => integer().withDefault(const Constant(0))();
  IntColumn get stoppedTimeMs => integer().withDefault(const Constant(0))();

  RealColumn get averageSpeedKmh => real().withDefault(const Constant(0.0))();
  RealColumn get maxSpeedKmh => real().withDefault(const Constant(0.0))();

  IntColumn get pointCount => integer().withDefault(const Constant(0))();
  IntColumn get stopCount => integer().withDefault(const Constant(0))();
  IntColumn get incidentCount => integer().withDefault(const Constant(0))();

  // ── AUDITORÍA DE SINCRONIZACIÓN CON LANÚS DIGITAL ──
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))(); // 'PENDING', 'SYNCED', 'FAILED'
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get remoteId => text().nullable()(); // ID devuelto por Postgres/Prisma

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

