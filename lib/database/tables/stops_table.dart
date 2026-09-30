import 'package:drift/drift.dart';
import 'trips_table.dart';

@DataClassName('StopEntry')
class Stops extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequence => integer().withDefault(const Constant(1))();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().nullable()();

  DateTimeColumn get markedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get arrivalAt => dateTime().nullable()();
  DateTimeColumn get departureAt => dateTime().nullable()();
  IntColumn get dwellTimeMs => integer().nullable()();

  TextColumn get name => text().nullable()();
  TextColumn get code => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('MANUAL'))(); // MANUAL, AUTO_DETECTED, CONFIRMED, IGNORED
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
