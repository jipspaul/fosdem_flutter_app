import 'package:drift/drift.dart';

@DataClassName('FavoriteEntity')
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().withDefault(const Constant('default'))();
  IntColumn get eventId => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}
