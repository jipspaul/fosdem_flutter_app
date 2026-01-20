import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/datasources/local/database.dart';
import '../../../../data/datasources/local/tables/events_table.dart';
import '../../domain/models/journey_models.dart';
import '../tables/journey_items_table.dart';

part 'journey_items_dao.g.dart';

@DriftAccessor(tables: [JourneyItems, Events])
class JourneyItemsDao extends DatabaseAccessor<AppDatabase> with _$JourneyItemsDaoMixin {
  JourneyItemsDao(super.db);

  // Get all journey items with event details
  Future<List<JourneyItemWithEvent>> getAllJourneyItems() async {
    final query = select(journeyItems).join([
      innerJoin(events, events.id.equalsExp(journeyItems.eventId)),
    ]);

    final results = await query.get();
    return results.map((row) {
      return JourneyItemWithEvent(
        journeyItem: row.readTable(journeyItems),
        event: row.readTable(events),
      );
    }).toList();
  }

  // Get journey items by status
  Future<List<JourneyItemWithEvent>> getJourneyItemsByStatus(JourneyStatus status) async {
    final query = select(journeyItems).join([
      innerJoin(events, events.id.equalsExp(journeyItems.eventId)),
    ])..where(journeyItems.status.equals(status.name));

    final results = await query.get();
    return results.map((row) {
      return JourneyItemWithEvent(
        journeyItem: row.readTable(journeyItems),
        event: row.readTable(events),
      );
    }).toList();
  }

  // Get wishlist items
  Future<List<JourneyItemWithEvent>> getWishlist() {
    return getJourneyItemsByStatus(JourneyStatus.wishlist);
  }

  // Get planned items (in journey)
  Future<List<JourneyItemWithEvent>> getPlannedItems() {
    return getJourneyItemsByStatus(JourneyStatus.planned);
  }

  // Add event to journey/wishlist
  Future<String> addJourneyItem({
    required int eventId,
    required JourneyStatus status,
    int priority = 3,
    String? notes,
    List<String> tags = const [],
  }) async {
    final id = const Uuid().v4();
    await into(journeyItems).insert(
      JourneyItemsCompanion(
        id: Value(id),
        eventId: Value(eventId),
        status: Value(status.name),
        priority: Value(priority),
        notes: Value(notes),
        tags: Value(jsonEncode(tags)),
      ),
    );
    return id;
  }

  // Update journey item
  Future<bool> updateJourneyItem(JourneyItemEntity item) {
    return update(journeyItems).replace(item);
  }

  // Update status
  Future<void> updateStatus(String id, JourneyStatus status) {
    return (update(journeyItems)..where((tbl) => tbl.id.equals(id)))
        .write(JourneyItemsCompanion(status: Value(status.name)));
  }

  // Update priority
  Future<void> updatePriority(String id, int priority) {
    return (update(journeyItems)..where((tbl) => tbl.id.equals(id)))
        .write(JourneyItemsCompanion(priority: Value(priority)));
  }

  // Update notes
  Future<void> updateNotes(String id, String? notes) {
    return (update(journeyItems)..where((tbl) => tbl.id.equals(id)))
        .write(JourneyItemsCompanion(notes: Value(notes)));
  }

  // Delete journey item
  Future<int> deleteJourneyItem(String id) {
    return (delete(journeyItems)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Check if event is in journey
  Future<bool> isEventInJourney(int eventId) async {
    final count = await (select(journeyItems)
          ..where((tbl) => tbl.eventId.equals(eventId)))
        .get();
    return count.isNotEmpty;
  }

  // Get journey item by event ID
  Future<JourneyItemEntity?> getJourneyItemByEventId(int eventId) async {
    final query = select(journeyItems)..where((tbl) => tbl.eventId.equals(eventId));
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  // Move from wishlist to planned
  Future<void> moveToPlanned(String id) {
    return updateStatus(id, JourneyStatus.planned);
  }

  // Move from planned to wishlist
  Future<void> moveToWishlist(String id) {
    return updateStatus(id, JourneyStatus.wishlist);
  }

  // Get items for a specific date
  Future<List<JourneyItemWithEvent>> getItemsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = select(journeyItems).join([
      innerJoin(events, events.id.equalsExp(journeyItems.eventId)),
    ])..where(
        events.start.isBiggerOrEqualValue(startOfDay) &
        events.start.isSmallerThanValue(endOfDay),
      );

    final results = await query.get();
    return results.map((row) {
      return JourneyItemWithEvent(
        journeyItem: row.readTable(journeyItems),
        event: row.readTable(events),
      );
    }).toList();
  }

  // Clear all journey items
  Future<void> clearAll() async {
    await delete(journeyItems).go();
  }
}

// Helper class to combine journey item with event
class JourneyItemWithEvent {
  final JourneyItemEntity journeyItem;
  final EventEntity event;

  JourneyItemWithEvent({
    required this.journeyItem,
    required this.event,
  });
}
