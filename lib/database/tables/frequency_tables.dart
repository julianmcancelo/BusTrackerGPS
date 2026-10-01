import 'package:drift/drift.dart';
import 'lines_table.dart';
import 'branches_table.dart';

@DataClassName('FrequencySessionEntry')
class FrequencySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()(); // e.g. "Control Estación Lanús - Hora Pico"
  TextColumn get checkpointName => text()(); // e.g. "Av. Hipólito Yrigoyen y 25 de Mayo"
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get targetLineIds => text().nullable()(); // JSON array of line IDs or null for open audit
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get auditorName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))(); // 'ACTIVE', 'COMPLETED'
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('FrequencyRecordEntry')
class FrequencyRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(FrequencySessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get lineId => integer().references(Lines, #id)();
  IntColumn get branchId => integer().references(Branches, #id)();
  TextColumn get direction => text()(); // 'IDA' or 'VUELTA'
  TextColumn get internalNumber => text().nullable()(); // coche / interno
  TextColumn get domain => text().nullable()(); // patente
  IntColumn get passengerLoad => integer().withDefault(const Constant(2))(); // 1=Baja, 2=Media, 3=Alta, 4=Colapso
  DateTimeColumn get observedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get headwaySeconds => integer().nullable()(); // seconds elapsed since previous bus of same line/branch/direction
  BoolColumn get isBunching => boolean().withDefault(const Constant(false))(); // headway <= 120s
  BoolColumn get isDelayed => boolean().withDefault(const Constant(false))(); // headway >= 1200s (20min)
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get notes => text().nullable()();
}
