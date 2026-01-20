import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/scraped_events_table.dart';

part 'scraped_events_dao.g.dart';

@DriftAccessor(tables: [ScrapedEvents])
class ScrapedEventsDao extends DatabaseAccessor<AppDatabase> with _$ScrapedEventsDaoMixin {
  ScrapedEventsDao(AppDatabase db) : super(db);

  // Get scraped event by event ID
  Future<ScrapedEventEntity?> getScrapedEvent(int eventId) {
    return (select(scrapedEvents)..where((e) => e.eventId.equals(eventId))).getSingleOrNull();
  }

  // Get scraped event if not expired
  Future<ScrapedEventEntity?> getValidScrapedEvent(int eventId) async {
    final scraped = await getScrapedEvent(eventId);
    if (scraped == null) return null;
    
    // Check if expired
    if (scraped.expiresAt != null && DateTime.now().isAfter(scraped.expiresAt!)) {
      return null; // Expired
    }
    
    return scraped;
  }

  // Save or update scraped event
  Future<void> upsertScrapedEvent(ScrapedEventsCompanion event) async {
    await into(scrapedEvents).insertOnConflictUpdate(event);
  }

  // Delete scraped event
  Future<int> deleteScrapedEvent(int eventId) {
    return (delete(scrapedEvents)..where((e) => e.eventId.equals(eventId))).go();
  }

  // Delete expired scraped events
  Future<int> deleteExpiredScrapedEvents() {
    return (delete(scrapedEvents)
      ..where((e) => e.expiresAt.isSmallerThanValue(DateTime.now()))).go();
  }

  // Get all scraped events
  Future<List<ScrapedEventEntity>> getAllScrapedEvents() {
    return select(scrapedEvents).get();
  }

  // Clear all scraped events
  Future<int> clearAll() {
    return delete(scrapedEvents).go();
  }
}
