import 'package:drift/drift.dart';

@DataClassName('LineEntry')
class Lines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text()();
  TextColumn get name => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
