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

  group('Database Integration Tests -', () {
    test('database initializes successfully', () async {
      expect(database, isNotNull);
      expect(database.schemaVersion, 1);
    });

    test('all DAOs are accessible', () {
      expect(database.eventsDao, isNotNull);
      expect(database.tracksDao, isNotNull);
      expect(database.peopleDao, isNotNull);
      expect(database.buildingsDao, isNotNull);
      expect(database.favoritesDao, isNotNull);
    });

    test('getDatabaseStats returns correct counts', () async {
      // Insert test data
      await database.eventsDao.insertEvents([
        EventsCompanion(
          id: const Value(1),
          title: const Value('Event 1'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 10, 0)),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ]);

      await database.tracksDao.insertTrack(
        const TracksCompanion(name: Value('Mobile')),
      );

      await database.peopleDao.insertPerson(
        const PeopleCompanion(name: Value('Speaker 1')),
      );

      final stats = await database.getDatabaseStats();

      expect(stats['events'], 1);
      expect(stats['tracks'], 1);
      expect(stats['people'], 1);
      expect(stats['buildings'], 0);
      expect(stats['favorites'], 0);
    });

    test('clearAllData removes all records', () async {
      // Insert data
      await database.eventsDao.insertEvents([
        EventsCompanion(
          id: const Value(1),
          title: const Value('Event 1'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 10, 0)),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ]);

      await database.tracksDao.insertTrack(
        const TracksCompanion(name: Value('Mobile')),
      );

      // Clear all
      await database.clearAllData();

      // Verify all empty
      final stats = await database.getDatabaseStats();
      expect(stats['events'], 0);
      expect(stats['tracks'], 0);
      expect(stats['people'], 0);
      expect(stats['buildings'], 0);
      expect(stats['favorites'], 0);
    });

    test('favorite integration with events', () async {
      // Insert event
      await database.eventsDao.insertEvents([
        EventsCompanion(
          id: const Value(1),
          title: const Value('Test Event'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 10, 0)),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ]);

      // Add to favorites
      await database.favoritesDao.addFavorite(1);

      // Verify in favorites
      final isFavorite = await database.favoritesDao.isFavorite(1);
      expect(isFavorite, true);

      // Also mark in events table
      await database.eventsDao.toggleFavorite(1, true);
      final event = await database.eventsDao.getEventById('1');
      expect(event!.isFavorite, true);

      // Get favorite events
      final favoriteEvents = await database.eventsDao.getFavoriteEvents();
      expect(favoriteEvents.length, 1);
    });

    test('batch insert performance', () async {
      final events = List.generate(
        100,
        (i) => EventsCompanion(
          id: Value(i),
          title: Value('Event $i'),
          room: const Value('H.1302'),
          track: const Value('Testing'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 10, i)),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      );

      final stopwatch = Stopwatch()..start();
      await database.eventsDao.insertEvents(events);
      stopwatch.stop();

      final allEvents = await database.eventsDao.getAllEvents();
      expect(allEvents.length, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
    });

    test('stream updates work across DAOs', () async {
      final eventStream = database.eventsDao.watchAllEvents();
      final favoritesStream = database.favoritesDao.watchFavoriteEventIds();

      // Insert event
      await database.eventsDao.insertEvents([
        EventsCompanion(
          id: const Value(1),
          title: const Value('Test Event'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 10, 0)),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ]);

      // Add to favorites
      await database.favoritesDao.addFavorite(1);

      // Streams should emit
      expect(eventStream, emits(isA<List<EventEntity>>()));
      expect(favoritesStream, emits(contains(1)));
    });

    test('transaction rollback works', () async {
      try {
        await database.transaction(() async {
          await database.eventsDao.insertEvents([
            EventsCompanion(
              id: const Value(1),
              title: const Value('Event 1'),
              room: const Value('H.1302'),
              track: const Value('Mobile'),
              date: Value(DateTime(2025, 2, 1)),
              start: Value(DateTime(2025, 2, 1, 10, 0)),
              duration: const Value(45),
              people: const Value('[]'),
              links: const Value('[]'),
              attachments: const Value('[]'),
            ),
          ]);

          // Force an error
          throw Exception('Test rollback');
        });
      } catch (e) {
        // Expected
      }

      // Verify nothing was inserted
      final events = await database.eventsDao.getAllEvents();
      expect(events.length, 0);
    });
  });
}
