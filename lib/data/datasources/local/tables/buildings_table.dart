import 'package:drift/drift.dart';

@DataClassName('BuildingEntity')
class Buildings extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get glyph => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get polygon => text()(); // JSON array of coordinates
  TextColumn get blueprints => text()(); // JSON array

  @override
  Set<Column> get primaryKey => {id};
}
