import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/swipe_history_table.dart';

part 'swipe_history_dao.g.dart';

@DriftAccessor(tables: [SwipeHistory])
class SwipeHistoryDao extends DatabaseAccessor<AppDatabase> with _$SwipeHistoryDaoMixin {
  SwipeHistoryDao(AppDatabase db) : super(db);

  Future<void> recordSwipe(String eventId, String action, {String userId = 'default'}) async {
    final id = '${userId}_$eventId';
    print('DEBUG SwipeHistoryDao: Recording swipe - ID: $id, EventID: $eventId, Action: $action');
    
    await into(swipeHistory).insert(
      SwipeHistoryCompanion.insert(
        id: id,
        eventId: eventId,
        userId: Value(userId),
        action: action,
      ),
      mode: InsertMode.insertOrReplace,
    );
    
    print('DEBUG SwipeHistoryDao: Swipe recorded successfully');
    
    // Verify it was saved
    final saved = await (select(swipeHistory)..where((s) => s.id.equals(id))).getSingleOrNull();
    print('DEBUG SwipeHistoryDao: Verification - ${saved != null ? "Found" : "NOT FOUND"}');
  }

  Future<Set<String>> getSeenEventIds({String userId = 'default'}) async {
    final results = await (select(swipeHistory)
          ..where((s) => s.userId.equals(userId)))
        .get();
    print('DEBUG SwipeHistoryDao: getSeenEventIds returned ${results.length} items for user $userId');
    return results.map((r) => r.eventId).toSet();
  }

  Future<List<SwipeHistoryData>> getSwipeHistory({String userId = 'default'}) async {
    return await (select(swipeHistory)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.swipedAt)]))
        .get();
  }

  Future<void> clearHistory({String userId = 'default'}) async {
    await (delete(swipeHistory)..where((s) => s.userId.equals(userId))).go();
  }
}
