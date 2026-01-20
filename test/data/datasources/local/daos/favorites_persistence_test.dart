import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/datasources/local/database.dart';
import 'package:fosdem_flutter/data/datasources/local/tables/events_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Favorites Persistence Tests', () {
    test('should preserve favorites when updating events', () async {
      // Create test event
      final event = EventsCompanion.insert(
        id: const Value(1),
        title: 'Test Event',
        track: 'Track A',
        date: DateTime(2024, 2, 3),
        start: DateTime(2024, 2, 3, 10, 0),
        duration: 60,
        room: 'Room 1',
        abstract: const Value('Abstract'),
        description: const Value('Description'),
        people: '[]',
        links: '[]',
        attachments: '[]',
        isFavorite: const Value(false),
      );

      // Insert event
      await database.eventsDao.upsertEvent(event);

      // Mark as favorite
      await database.eventsDao.setFavorite('1', true);

      // Verify it's favorited
      var favorites = await database.eventsDao.getFavoriteEvents();
      expect(favorites.length, equals(1));
      expect(favorites.first.id, equals(1));
      expect(favorites.first.isFavorite, isTrue);

      // Simulate app restart: reload event from API (without favorite flag)
      final updatedEvent = EventsCompanion.insert(
        id: const Value(1),
        title: 'Test Event - Updated',
        track: 'Track A',
        date: DateTime(2024, 2, 3),
        start: DateTime(2024, 2, 3, 10, 0),
        duration: 60,
        room: 'Room 1',
        abstract: const Value('Updated Abstract'),
        description: const Value('Updated Description'),
        people: '[]',
        links: '[]',
        attachments: '[]',
        isFavorite: const Value(false), // API always returns false
      );

      await database.eventsDao.upsertEvent(updatedEvent);

      // Verify favorite is STILL preserved
      favorites = await database.eventsDao.getFavoriteEvents();
      expect(favorites.length, equals(1), reason: 'Favorite should be preserved after update');
      expect(favorites.first.id, equals(1));
      expect(favorites.first.isFavorite, isTrue, reason: 'isFavorite should still be true');
      expect(favorites.first.title, equals('Test Event - Updated'), reason: 'Other fields should be updated');
    });

    test('should preserve multiple favorites in batch insert', () async {
      // Insert initial events and mark some as favorites
      final events = [
        EventsCompanion.insert(
          id: const Value(1),
          title: 'Event 1',
          track: 'Test Track',
          date: DateTime(2024, 2, 3),
          start: DateTime(2024, 2, 3, 10, 0),
          duration: 60,
          room: 'Room 1',
          people: '[]',
          links: '[]',
          attachments: '[]',
        ),
        EventsCompanion.insert(
          id: const Value(2),
          title: 'Event 2',
          track: 'Test Track',
          date: DateTime(2024, 2, 3),
          start: DateTime(2024, 2, 3, 11, 0),
          duration: 60,
          room: 'Room 2',
          people: '[]',
          links: '[]',
          attachments: '[]',
        ),
        EventsCompanion.insert(
          id: const Value(3),
          title: 'Event 3',
          track: 'Test Track',
          date: DateTime(2024, 2, 3),
          start: DateTime(2024, 2, 3, 12, 0),
          duration: 60,
          room: 'Room 3',
          people: '[]',
          links: '[]',
          attachments: '[]',
        ),
      ];

      await database.eventsDao.insertEvents(events);

      // Mark events 1 and 3 as favorites
      await database.eventsDao.setFavorite('1', true);
      await database.eventsDao.setFavorite('3', true);

      var favorites = await database.eventsDao.getFavoriteEvents();
      expect(favorites.length, equals(2));
      expect(favorites.map((e) => e.id).toSet(), equals({1, 3}));

      // Simulate batch update from API (all events with isFavorite=false)
      final updatedEvents = [
        EventsCompanion.insert(
          id: const Value(1),
          title: 'Event 1 Updated',
          track: 'Test Track',
          date: DateTime(2024, 2, 3),
          start: DateTime(2024, 2, 3, 10, 0),
          duration: 60,
          room: 'Room 1',
          people: '[]',
          links: '[]',
          attachments: '[]',
          isFavorite: const Value(false), // API sends false
        ),
        EventsCompanion.insert(
          id: const Value(2),
          title: 'Event 2 Updated',
          track: 'Test Track',
          date: DateTime(2024, 2, 3),
          start: DateTime(2024, 2, 3, 11, 0),
          duration: 60,
          room: 'Room 2',
          people: '[]',
          links: '[]',
          attachments: '[]',
          isFavorite: const Value(false),
        ),
        EventsCompanion.insert(
          id: const Value(3),
          title: 'Event 3 Updated',
          track: 'Test Track',
          date: DateTime(2024, 2, 3),
          start: DateTime(2024, 2, 3, 12, 0),
          duration: 60,
          room: 'Room 3',
          people: '[]',
          links: '[]',
          attachments: '[]',
          isFavorite: const Value(false),
        ),
      ];

      await database.eventsDao.insertEvents(updatedEvents);

      // Verify favorites are STILL preserved
      favorites = await database.eventsDao.getFavoriteEvents();
      expect(favorites.length, equals(2), reason: 'Should still have 2 favorites');
      expect(favorites.map((e) => e.id).toSet(), equals({1, 3}), reason: 'Events 1 and 3 should still be favorites');
      expect(favorites.first.title, contains('Updated'), reason: 'Titles should be updated');
    });

    test('should toggle favorite on and off', () async {
      final event = EventsCompanion.insert(
        id: const Value(1),
        title: 'Toggle Test',
        track: 'Test Track',
        date: DateTime(2024, 2, 3),
        start: DateTime(2024, 2, 3, 10, 0),
        duration: 60,
        room: 'Room 1',
        people: '[]',
        links: '[]',
        attachments: '[]',
      );

      await database.eventsDao.upsertEvent(event);

      // Initially not favorite
      var favorites = await database.eventsDao.getFavoriteEvents();
      expect(favorites.length, equals(0));

      // Mark as favorite
      await database.eventsDao.setFavorite('1', true);
      favorites = await database.eventsDao.getFavoriteEvents();
      expect(favorites.length, equals(1));

      // Remove from favorites
      await database.eventsDao.setFavorite('1', false);
      favorites = await database.eventsDao.getFavoriteEvents();
      expect(favorites.length, equals(0));

      // Mark as favorite again
      await database.eventsDao.setFavorite('1', true);
      favorites = await database.eventsDao.getFavoriteEvents();
      expect(favorites.length, equals(1));
    });

    test('should check if event is favorite', () async {
      final event = EventsCompanion.insert(
        id: const Value(1),
        title: 'Check Test',
        track: 'Test Track',
        date: DateTime(2024, 2, 3),
        start: DateTime(2024, 2, 3, 10, 0),
        duration: 60,
        room: 'Room 1',
        people: '[]',
        links: '[]',
        attachments: '[]',
      );

      await database.eventsDao.upsertEvent(event);

      // Initially not favorite
      var isFav = await database.eventsDao.isFavorite('1');
      expect(isFav, isFalse);

      // Mark as favorite
      await database.eventsDao.setFavorite('1', true);
      isFav = await database.eventsDao.isFavorite('1');
      expect(isFav, isTrue);

      // Remove favorite
      await database.eventsDao.setFavorite('1', false);
      isFav = await database.eventsDao.isFavorite('1');
      expect(isFav, isFalse);
    });
  });
}
