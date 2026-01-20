import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/cache_metadata_table.dart';

part 'cache_dao.g.dart';

@DriftAccessor(tables: [CacheMetadataTable])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  CacheDao(AppDatabase db) : super(db);

  Future<CacheMetadata?> getCacheMetadata(String key) =>
      (select(cacheMetadataTable)..where((c) => c.key.equals(key))).getSingleOrNull();

  Future<List<CacheMetadata>> getAllCacheMetadata() =>
      select(cacheMetadataTable).get();

  Future<List<CacheMetadata>> getCacheByCategory(String category) =>
      (select(cacheMetadataTable)..where((c) => c.category.equals(category))).get();

  Future<int> insertOrUpdateCache(CacheMetadataTableCompanion entry) =>
      into(cacheMetadataTable).insertOnConflictUpdate(entry);

  Future<void> updateAccessInfo(String key) async {
    final existing = await getCacheMetadata(key);
    if (existing != null) {
      await (update(cacheMetadataTable)..where((c) => c.key.equals(key))).write(
        CacheMetadataTableCompanion(
          accessCount: Value(existing.accessCount + 1),
          lastAccessedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<int> deleteCache(String key) =>
      (delete(cacheMetadataTable)..where((c) => c.key.equals(key))).go();

  Future<int> clearExpiredCache() async {
    final now = DateTime.now();
    return (delete(cacheMetadataTable)..where((c) => c.expiresAt.isSmallerThanValue(now))).go();
  }

  Future<int> clearCacheByCategory(String category) =>
      (delete(cacheMetadataTable)..where((c) => c.category.equals(category))).go();

  Future<int> clearAllCache() => delete(cacheMetadataTable).go();

  Future<int> getTotalCacheSize() async {
    final query = selectOnly(cacheMetadataTable)..addColumns([cacheMetadataTable.sizeBytes.sum()]);
    final result = await query.getSingleOrNull();
    return result?.read(cacheMetadataTable.sizeBytes.sum()) ?? 0;
  }

  Future<List<CacheMetadata>> getLeastRecentlyUsed(int limit) =>
      (select(cacheMetadataTable)
        ..orderBy([(c) => OrderingTerm.asc(c.lastAccessedAt ?? c.createdAt)])
        ..limit(limit))
          .get();
}
