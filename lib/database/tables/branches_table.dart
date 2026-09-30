import 'package:drift/drift.dart';
import 'lines_table.dart';

@DataClassName('BranchEntry')
class Branches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lineId => integer().references(Lines, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
