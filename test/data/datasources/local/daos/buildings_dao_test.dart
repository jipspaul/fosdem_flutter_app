import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fosdem_flutter/data/datasources/local/database.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.test(NativeDatabase.memory());
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  group('BuildingsDao -', () {
    test('insertBuilding and getBuildingById works', () async {
      final building = const BuildingsCompanion(
        id: Value('H'),
        title: Value('H Building'),
        glyph: Value('H'),
        latitude: Value(50.8137),
        longitude: Value(4.3805),
        polygon: Value('[]'),
        blueprints: Value('[]'),
      );

      await database.buildingsDao.insertBuilding(building);
      final retrieved = await database.buildingsDao.getBuildingById('H');

      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'H Building');
      expect(retrieved.latitude, 50.8137);
      expect(retrieved.longitude, 4.3805);
    });

    test('getAllBuildings returns all buildings', () async {
      final buildings = [
        const BuildingsCompanion(
          id: Value('H'),
          title: Value('H Building'),
          glyph: Value('H'),
          latitude: Value(50.8137),
          longitude: Value(4.3805),
          polygon: Value('[]'),
          blueprints: Value('[]'),
        ),
        const BuildingsCompanion(
          id: Value('K'),
          title: Value('K Building'),
          glyph: Value('K'),
          latitude: Value(50.8140),
          longitude: Value(4.3810),
          polygon: Value('[]'),
          blueprints: Value('[]'),
        ),
      ];

      await database.buildingsDao.insertBuildings(buildings);
      final retrieved = await database.buildingsDao.getAllBuildings();

      expect(retrieved.length, 2);
    });

    test('deleteBuilding removes building', () async {
      final building = const BuildingsCompanion(
        id: Value('H'),
        title: Value('H Building'),
        glyph: Value('H'),
        latitude: Value(50.8137),
        longitude: Value(4.3805),
        polygon: Value('[]'),
        blueprints: Value('[]'),
      );

      await database.buildingsDao.insertBuilding(building);
      await database.buildingsDao.deleteBuilding('H');

      expect(await database.buildingsDao.getBuildingById('H'), isNull);
    });
  });
}
