import 'package:drift/drift.dart';

@DataClassName('OfflineMapRegionEntry')
class OfflineMapRegions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  IntColumn get minZoom => integer()();
  IntColumn get maxZoom => integer()();

  RealColumn get minLat => real()();
  RealColumn get minLng => real()();
  RealColumn get maxLat => real()();
  RealColumn get maxLng => real()();

  TextColumn get mbTilesPath => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
