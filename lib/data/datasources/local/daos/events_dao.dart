import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/events_table.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(AppDatabase db) : super(db);

  // Get all events
  Future<List<EventEntity>> getAllEvents({int? limit, int? offset}) {
    final query = select(events)..orderBy([(e) => OrderingTerm.asc(e.start)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  // Get event by ID
  Future<EventEntity?> getEventById(String id) {
    final intId = int.tryParse(id);
    if (intId == null) return Future.value(null);
    return (select(events)..where((e) => e.id.equals(intId))).getSingleOrNull();
  }

  // Get event by int ID
  Future<EventEntity?> getEventByIntId(int id) {
    return (select(events)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  // Get events by track
  Future<List<EventEntity>> getEventsByTrack(String track) =>
      (select(events)..where((e) => e.track.equals(track))).get();

  // Get events by room
  Future<List<EventEntity>> getEventsByRoom(String room) =>
      (select(events)..where((e) => e.room.equals(room))).get();

  // Get events by date range
  Future<List<EventEntity>> getEventsByDateRange(DateTime start, DateTime end) =>
      (select(events)
            ..where((e) => e.start.isBetweenValues(start, end))
            ..orderBy([(e) => OrderingTerm.asc(e.start)]))
          .get();

  // Get events by day
  Future<List<EventEntity>> getEventsByDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getEventsByDateRange(startOfDay, endOfDay);
  }

  // Get favorite events
  Future<List<EventEntity>> getFavoriteEvents() =>
      (select(events)..where((e) => e.isFavorite.equals(true))).get();

  // Get upcoming events
  Future<List<EventEntity>> getUpcomingEvents({int limit = 10}) {
    final now = DateTime.now();
    return (select(events)
          ..where((e) => e.start.isBiggerThanValue(now))
          ..orderBy([(e) => OrderingTerm.asc(e.start)])
          ..limit(limit))
        .get();
  }

  // Get happening now events
  Future<List<EventEntity>> getHappeningNowEvents() {
    final now = DateTime.now();
    return (select(events)
          ..where((e) => 
              e.start.isSmallerOrEqualValue(now) &
              e.start.isBiggerOrEqualValue(now.subtract(Duration(hours: 6)))))
        .get();
  }

  // Insert or update event - preserves favorite status
  Future<int> upsertEvent(EventsCompanion event) async {
    // Check if event exists and has favorite set
    final eventId = event.id.value;
    final existing = await (select(events)..where((e) => e.id.equals(eventId))).getSingleOrNull();
    
    if (existing != null && existing.isFavorite) {
      // Preserve the favorite status
      final updatedEvent = event.copyWith(isFavorite: Value(true));
      return await into(events).insertOnConflictUpdate(updatedEvent);
    }
    
    return await into(events).insertOnConflictUpdate(event);
  }

  // Insert multiple events (batch) - preserves favorites  
  Future<void> insertEvents(List<EventsCompanion> eventsList) async {
    if (eventsList.isEmpty) {
      return; // Nothing to insert
    }
    
    // Get all existing favorites before insert
    final existingFavorites = await getFavoriteEvents();
    final favoriteIds = existingFavorites.map((e) => e.id).toSet();
    
    await batch((batch) {
      for (final event in eventsList) {
        // Get event ID safely
        if (!event.id.present) {
          // Skip events without IDs
          continue;
        }
        
        final eventId = event.id.value;
        // If event was a favorite, ensure it stays a favorite
        if (favoriteIds.contains(eventId)) {
          final eventWithFavorite = event.copyWith(isFavorite: const Value(true));
          batch.insert(events, eventWithFavorite, mode: InsertMode.insertOrReplace);
        } else {
          batch.insert(events, event, mode: InsertMode.insertOrReplace);
        }
      }
    });
  }

  // Update event
  Future<bool> updateEvent(EventEntity event) => update(events).replace(event);

  // Delete event
  Future<int> deleteEvent(int id) =>
      (delete(events)..where((e) => e.id.equals(id))).go();

  // Toggle favorite
  Future<void> toggleFavorite(int eventId, bool isFavorite) async {
    await (update(events)..where((e) => e.id.equals(eventId)))
        .write(EventsCompanion(isFavorite: Value(isFavorite)));
  }

  // Count events by track
  Future<Map<String, int>> countEventsByTrack() async {
    final result = await customSelect(
      'SELECT track, COUNT(*) as count FROM events GROUP BY track',
      readsFrom: {events},
    ).get();
    
    return {
      for (var row in result) row.read<String>('track'): row.read<int>('count')
    };
  }

  // Get all tracks from events
  Future<List<String>> getAllTracks() async {
    final result = await customSelect(
      'SELECT DISTINCT track FROM events ORDER BY track',
      readsFrom: {events},
    ).get();
    
    return result.map((row) => row.read<String>('track')).toList();
  }

  // Get all rooms from events
  Future<List<String>> getAllRooms() async {
    final result = await customSelect(
      'SELECT DISTINCT room FROM events ORDER BY room',
      readsFrom: {events},
    ).get();
    
    return result.map((row) => row.read<String>('room')).toList();
  }

  // Stream all events
  Stream<List<EventEntity>> watchAllEvents() => select(events).watch();

  // Stream events by track
  Stream<List<EventEntity>> watchEventsByTrack(String track) =>
      (select(events)..where((e) => e.track.equals(track))).watch();

  // Stream favorite events
  Stream<List<EventEntity>> watchFavoriteEvents() =>
      (select(events)..where((e) => e.isFavorite.equals(true))).watch();

  // Search events
  Future<List<EventEntity>> searchEvents(String query) {
    final searchTerm = '%${query.toLowerCase()}%';
    return (select(events)
          ..where((e) =>
              e.title.lower().like(searchTerm) |
              e.abstract.lower().like(searchTerm) |
              e.description.lower().like(searchTerm)))
        .get();
  }

  // Get events by track with filters
  Future<List<EventEntity>> getEventsByTrackFiltered({
    String? trackName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final query = select(events);
    if (trackName != null) {
      query.where((e) => e.track.equals(trackName));
    }
    if (startDate != null && endDate != null) {
      query.where((e) => e.start.isBetweenValues(startDate, endDate));
    }
    query.orderBy([(e) => OrderingTerm.asc(e.start)]);
    return query.get();
  }

  // Watch single event
  Stream<EventEntity?> watchEvent(String id) {
    final intId = int.tryParse(id);
    if (intId == null) return Stream.value(null);
    return (select(events)..where((e) => e.id.equals(intId))).watchSingleOrNull();
  }

  // Insert event (alias for upsert)
  Future<int> insertEvent(EventsCompanion event) => upsertEvent(event);

  // Set favorite status
  Future<void> setFavorite(String eventId, bool isFavorite) async {
    final intId = int.tryParse(eventId);
    if (intId != null) {
      await toggleFavorite(intId, isFavorite);
    }
  }

  // Check if event is favorite
  Future<bool> isFavorite(String eventId) async {
    final intId = int.tryParse(eventId);
    if (intId == null) return false;
    final event = await (select(events)..where((e) => e.id.equals(intId))).getSingleOrNull();
    return event?.isFavorite ?? false;
  }

  // Delete all events
  Future<int> deleteAllEvents() => delete(events).go();
}
