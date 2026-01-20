import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/favorites_table.dart';

part 'favorites_dao.g.dart';

@DriftAccessor(tables: [Favorites])
class FavoritesDao extends DatabaseAccessor<AppDatabase> with _$FavoritesDaoMixin {
  FavoritesDao(AppDatabase db) : super(db);

  Future<List<FavoriteEntity>> getAllFavorites({String userId = 'default'}) =>
      (select(favorites)..where((f) => f.userId.equals(userId))).get();
  
  Future<List<int>> getFavoriteEventIds({String userId = 'default'}) async {
    final favs = await getAllFavorites(userId: userId);
    return favs.map((f) => f.eventId).toList();
  }
  
  Future<List<int>> getAllFavoriteIds({String userId = 'default'}) async {
    return getFavoriteEventIds(userId: userId);
  }
  
  Future<bool> isFavorite(int eventId, {String userId = 'default'}) async {
    final result = await (select(favorites)
          ..where((f) => f.userId.equals(userId) & f.eventId.equals(eventId)))
        .getSingleOrNull();
    return result != null;
  }
  
  Future<int> addFavorite(int eventId, {String userId = 'default'}) =>
      into(favorites).insert(
        FavoritesCompanion(
          userId: Value(userId),
          eventId: Value(eventId),
        ),
        mode: InsertMode.insertOrIgnore,
      );
  
  Future<int> removeFavorite(int eventId, {String userId = 'default'}) =>
      (delete(favorites)
            ..where((f) => f.userId.equals(userId) & f.eventId.equals(eventId)))
          .go();
  
  Future<void> toggleFavorite(int eventId, {String userId = 'default'}) async {
    final isFav = await isFavorite(eventId, userId: userId);
    if (isFav) {
      await removeFavorite(eventId, userId: userId);
    } else {
      await addFavorite(eventId, userId: userId);
    }
  }
  
  Stream<List<FavoriteEntity>> watchFavorites({String userId = 'default'}) =>
      (select(favorites)..where((f) => f.userId.equals(userId))).watch();
  
  Stream<List<int>> watchFavoriteEventIds({String userId = 'default'}) =>
      watchFavorites(userId: userId).map((favs) => favs.map((f) => f.eventId).toList());
}
