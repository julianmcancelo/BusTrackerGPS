import 'package:drift/drift.dart';
import 'trips_table.dart';

@DataClassName('IncidentEntry')
class Incidents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().nullable()();

  TextColumn get type => text()(); // OBRA, CORTE, DESVIO, TRANSITO, PARADA, CALZADA, UNIDAD, ACCIDENTE, OTRO
  TextColumn get severity => text().withDefault(const Constant('LOW'))(); // LOW, MEDIUM, HIGH, CRITICAL
  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
