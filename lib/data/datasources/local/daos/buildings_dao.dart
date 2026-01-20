import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/buildings_table.dart';

part 'buildings_dao.g.dart';

@DriftAccessor(tables: [Buildings])
class BuildingsDao extends DatabaseAccessor<AppDatabase> with _$BuildingsDaoMixin {
  BuildingsDao(AppDatabase db) : super(db);

  Future<List<BuildingEntity>> getAllBuildings() => select(buildings).get();
  
  Future<BuildingEntity?> getBuildingById(String id) =>
      (select(buildings)..where((b) => b.id.equals(id))).getSingleOrNull();
  
  Future<void> insertBuilding(BuildingsCompanion building) =>
      into(buildings).insert(building, mode: InsertMode.insertOrReplace);
  
  Future<void> insertBuildings(List<BuildingsCompanion> buildingsList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(buildings, buildingsList);
    });
  }
  
  Future<bool> updateBuilding(BuildingEntity building) =>
      update(buildings).replace(building);
  
  Future<int> deleteBuilding(String id) =>
      (delete(buildings)..where((b) => b.id.equals(id))).go();
  
  Stream<List<BuildingEntity>> watchAllBuildings() => select(buildings).watch();
}
