import 'package:drift/drift.dart';

class SwipeHistory extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get userId => text().withDefault(const Constant('default'))();
  TextColumn get action => text()(); // 'like', 'dislike', 'skip'
  DateTimeColumn get swipedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
