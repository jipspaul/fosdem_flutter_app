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

  group('EventsDao -', () {
    test('insertEvent and getEventById works', () async {
      final event = EventsCompanion(
        id: const Value(1),
        title: const Value('Test Event'),
        room: const Value('H.1302'),
        track: const Value('Testing'),
        date: Value(DateTime(2025, 2, 1)),
        start: Value(DateTime(2025, 2, 1, 10, 0)),
        duration: const Value(45),
        people: const Value('[]'),
        links: const Value('[]'),
        attachments: const Value('[]'),
      );

      await database.eventsDao.upsertEvent(event);
      final retrieved = await database.eventsDao.getEventById('1');

      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Test Event');
      expect(retrieved.room, 'H.1302');
      expect(retrieved.duration, 45);
    });

    test('getAllEvents returns all inserted events', () async {
      final events = [
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
        EventsCompanion(
          id: const Value(2),
          title: const Value('Event 2'),
          room: const Value('H.1303'),
          track: const Value('Web'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 11, 0)),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ];

      await database.eventsDao.insertEvents(events);
      final retrieved = await database.eventsDao.getAllEvents();

      expect(retrieved.length, 2);
    });

    test('getEventsByTrack filters correctly', () async {
      final events = [
        EventsCompanion(
          id: const Value(1),
          title: const Value('Mobile Event'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 10, 0)),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(2),
          title: const Value('Web Event'),
          room: const Value('H.1303'),
          track: const Value('Web'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 11, 0)),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ];

      await database.eventsDao.insertEvents(events);
      final mobileEvents = await database.eventsDao.getEventsByTrack('Mobile');

      expect(mobileEvents.length, 1);
      expect(mobileEvents[0].track, 'Mobile');
    });

    test('toggleFavorite works', () async {
      final event = EventsCompanion(
        id: const Value(1),
        title: const Value('Test Event'),
        room: const Value('H.1302'),
        track: const Value('Testing'),
        date: Value(DateTime(2025, 2, 1)),
        start: Value(DateTime(2025, 2, 1, 10, 0)),
        duration: const Value(45),
        people: const Value('[]'),
        links: const Value('[]'),
        attachments: const Value('[]'),
      );

      await database.eventsDao.upsertEvent(event);
      await database.eventsDao.toggleFavorite(1, true);
      
      var retrieved = await database.eventsDao.getEventById('1');
      expect(retrieved!.isFavorite, true);
    });

    test('deleteEvent removes event', () async {
      final event = EventsCompanion(
        id: const Value(1),
        title: const Value('Test Event'),
        room: const Value('H.1302'),
        track: const Value('Testing'),
        date: Value(DateTime(2025, 2, 1)),
        start: Value(DateTime(2025, 2, 1, 10, 0)),
        duration: const Value(45),
        people: const Value('[]'),
        links: const Value('[]'),
        attachments: const Value('[]'),
      );

      await database.eventsDao.upsertEvent(event);
      await database.eventsDao.deleteEvent(1);
      
      expect(await database.eventsDao.getEventById('1'), isNull);
    });
  });
}
