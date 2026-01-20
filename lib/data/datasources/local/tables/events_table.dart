import 'package:drift/drift.dart';

@DataClassName('EventEntity')
class Events extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get abstract => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get room => text()();
  TextColumn get track => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get start => dateTime()();
  IntColumn get duration => integer()(); // minutes
  TextColumn get people => text()(); // JSON array
  TextColumn get links => text()(); // JSON array
  TextColumn get attachments => text()(); // JSON array
  TextColumn get url => text().nullable()(); // Event URL for scraping details
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
