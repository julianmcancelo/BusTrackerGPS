import 'package:drift/drift.dart';
import 'trips_table.dart';

@DataClassName('TrackPointEntry')
class TrackPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get elapsedRealtimeNanos => integer().nullable()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  RealColumn get altitude => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  RealColumn get speedMps => real().nullable()();
  RealColumn get bearingDegrees => real().nullable()();

  TextColumn get provider => text().nullable()();

  TextColumn get quality => text().withDefault(const Constant('GOOD'))(); // GOOD, LOW_ACCURACY, OUTLIER
  BoolColumn get isAccepted => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
