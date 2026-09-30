import 'package:drift/drift.dart';
import 'lines_table.dart';
import 'branches_table.dart';

@DataClassName('ReferenceRouteEntry')
class ReferenceRoutes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lineId => integer().references(Lines, #id, onDelete: KeyAction.cascade)();
  IntColumn get branchId => integer().references(Branches, #id, onDelete: KeyAction.cascade)();

  TextColumn get direction => text()(); // 'IDA' or 'VUELTA'
  TextColumn get name => text()();
  TextColumn get format => text()(); // 'GPX', 'GEOJSON', 'KML'
  TextColumn get geoJsonData => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
