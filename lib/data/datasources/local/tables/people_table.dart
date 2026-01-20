import 'package:drift/drift.dart';

@DataClassName('PersonEntity')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get bio => text().nullable()();
  TextColumn get avatar => text().nullable()();
}
