import 'package:flutter_test/flutter_test.dart' hide isNotNull, isNull;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fosdem_flutter/data/datasources/local/database.dart';
import 'package:matcher/matcher.dart' show isNotNull, isNull;

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

  group('FavoritesDao -', () {
    test('addFavorite and isFavorite works', () async {
      await database.favoritesDao.addFavorite(1);
      final isFav = await database.favoritesDao.isFavorite(1);
      expect(isFav, true);
    });

    test('toggleFavorite works', () async {
      await database.favoritesDao.toggleFavorite(1);
      expect(await database.favoritesDao.isFavorite(1), true);
      
      await database.favoritesDao.toggleFavorite(1);
      expect(await database.favoritesDao.isFavorite(1), false);
    });

    test('getFavoriteEventIds returns correct IDs', () async {
      await database.favoritesDao.addFavorite(1);
      await database.favoritesDao.addFavorite(2);

      final ids = await database.favoritesDao.getFavoriteEventIds();
      expect(ids.length, 2);
    });
  });
}
