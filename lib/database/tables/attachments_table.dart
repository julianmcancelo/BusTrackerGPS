import 'package:drift/drift.dart';
import 'trips_table.dart';
import 'stops_table.dart';
import 'incidents_table.dart';

@DataClassName('AttachmentEntry')
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  IntColumn get stopId => integer().nullable().references(Stops, #id, onDelete: KeyAction.setNull)();
  IntColumn get incidentId => integer().nullable().references(Incidents, #id, onDelete: KeyAction.setNull)();

  TextColumn get type => text()(); // PHOTO, AUDIO, FILE
  TextColumn get filePath => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get fileSizeBytes => integer().nullable()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
