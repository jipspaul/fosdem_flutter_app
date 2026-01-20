import 'package:drift/drift.dart';
import '../../../../data/datasources/local/tables/events_table.dart';

@DataClassName('JourneyItemEntity')
class JourneyItems extends Table {
  TextColumn get id => text()();
  IntColumn get eventId => integer().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => text()(); // JourneyStatus enum as string
  IntColumn get priority => integer().withDefault(const Constant(3))(); // 1-5
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array

  @override
  Set<Column> get primaryKey => {id};
}
