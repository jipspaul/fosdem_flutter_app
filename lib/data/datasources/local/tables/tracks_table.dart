import 'package:drift/drift.dart';

@DataClassName('TrackEntity')
class Tracks extends Table {
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('track'))();
  TextColumn get description => text().nullable()();
  IntColumn get day => integer().nullable()();
  DateTimeColumn get date => dateTime().nullable()();
  TextColumn get colorHex => text().nullable()();

  @override
  Set<Column> get primaryKey => {name};
}
