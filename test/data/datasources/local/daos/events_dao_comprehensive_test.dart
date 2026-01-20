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

  group('EventsDao Comprehensive Tests -', () {
    test('getEventsByRoom filters correctly', () async {
      final events = [
        EventsCompanion(
          id: const Value(1),
          title: const Value('Room 1 Event'),
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
          title: const Value('Room 2 Event'),
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
      final roomEvents = await database.eventsDao.getEventsByRoom('H.1302');

      expect(roomEvents.length, 1);
      expect(roomEvents[0].room, 'H.1302');
    });

    test('getEventsByDateRange filters correctly', () async {
      final day1 = DateTime(2025, 2, 1, 10, 0);
      final day2 = DateTime(2025, 2, 2, 10, 0);
      final day3 = DateTime(2025, 2, 3, 10, 0);

      final events = [
        EventsCompanion(
          id: const Value(1),
          title: const Value('Day 1'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(day1),
          start: Value(day1),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(2),
          title: const Value('Day 2'),
          room: const Value('H.1303'),
          track: const Value('Web'),
          date: Value(day2),
          start: Value(day2),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(3),
          title: const Value('Day 3'),
          room: const Value('H.1304'),
          track: const Value('Web'),
          date: Value(day3),
          start: Value(day3),
          duration: const Value(60),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ];

      await database.eventsDao.insertEvents(events);
      final rangeEvents = await database.eventsDao.getEventsByDateRange(day1, day2.add(const Duration(hours: 1)));

      expect(rangeEvents.length, 2);
      expect(rangeEvents.map((e) => e.title), containsAll(['Day 1', 'Day 2']));
    });

    test('getEventsByDay filters correctly', () async {
      final day1 = DateTime(2025, 2, 1);
      final day2 = DateTime(2025, 2, 2);

      final events = [
        EventsCompanion(
          id: const Value(1),
          title: const Value('Day 1 Morning'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(day1),
          start: Value(DateTime(2025, 2, 1, 9, 0)),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(2),
          title: const Value('Day 1 Afternoon'),
          room: const Value('H.1303'),
          track: const Value('Web'),
          date: Value(day1),
          start: Value(DateTime(2025, 2, 1, 14, 0)),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(3),
          title: const Value('Day 2 Event'),
          room: const Value('H.1304'),
          track: const Value('Security'),
          date: Value(day2),
          start: Value(DateTime(2025, 2, 2, 10, 0)),
          duration: const Value(60),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ];

      await database.eventsDao.insertEvents(events);
      final day1Events = await database.eventsDao.getEventsByDay(day1);

      expect(day1Events.length, 2);
      expect(day1Events.map((e) => e.title), containsAll(['Day 1 Morning', 'Day 1 Afternoon']));
    });

    test('getUpcomingEvents returns future events', () async {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final future1 = DateTime.now().add(const Duration(hours: 1));
      final future2 = DateTime.now().add(const Duration(hours: 2));

      final events = [
        EventsCompanion(
          id: const Value(1),
          title: const Value('Past Event'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(past),
          start: Value(past),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(2),
          title: const Value('Future Event 1'),
          room: const Value('H.1303'),
          track: const Value('Web'),
          date: Value(future1),
          start: Value(future1),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(3),
          title: const Value('Future Event 2'),
          room: const Value('H.1304'),
          track: const Value('Security'),
          date: Value(future2),
          start: Value(future2),
          duration: const Value(60),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ];

      await database.eventsDao.insertEvents(events);
      final upcoming = await database.eventsDao.getUpcomingEvents(limit: 10);

      expect(upcoming.length, 2);
      expect(upcoming.every((e) => e.start.isAfter(DateTime.now())), true);
    });

    test('getFavoriteEvents returns only favorites', () async {
      final events = [
        EventsCompanion(
          id: const Value(1),
          title: const Value('Favorite Event'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 10, 0)),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
          isFavorite: const Value(true),
        ),
        EventsCompanion(
          id: const Value(2),
          title: const Value('Regular Event'),
          room: const Value('H.1303'),
          track: const Value('Web'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 11, 0)),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
          isFavorite: const Value(false),
        ),
      ];

      await database.eventsDao.insertEvents(events);
      final favorites = await database.eventsDao.getFavoriteEvents();

      expect(favorites.length, 1);
      expect(favorites[0].title, 'Favorite Event');
    });

    test('getAllTracks returns distinct tracks sorted', () async {
      final events = [
        EventsCompanion(
          id: const Value(1),
          title: const Value('Event 1'),
          room: const Value('H.1302'),
          track: const Value('Zebra'),
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
          track: const Value('Apple'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 11, 0)),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(3),
          title: const Value('Event 3'),
          room: const Value('H.1304'),
          track: const Value('Mobile'),
          date: Value(DateTime(2025, 2, 1)),
          start: Value(DateTime(2025, 2, 1, 12, 0)),
          duration: const Value(60),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ];

      await database.eventsDao.insertEvents(events);
      final tracks = await database.eventsDao.getAllTracks();

      expect(tracks.length, 3);
      expect(tracks[0], 'Apple'); // Should be sorted
    });

    test('getAllRooms returns distinct rooms sorted', () async {
      final events = [
        EventsCompanion(
          id: const Value(1),
          title: const Value('Event 1'),
          room: const Value('H.1304'),
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
          room: const Value('H.1302'),
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
      final rooms = await database.eventsDao.getAllRooms();

      expect(rooms.length, 2);
      expect(rooms[0], 'H.1302'); // Should be sorted
    });

    test('updateEvent modifies existing event', () async {
      final event = EventsCompanion(
        id: const Value(1),
        title: const Value('Original Title'),
        room: const Value('H.1302'),
        track: const Value('Mobile'),
        date: Value(DateTime(2025, 2, 1)),
        start: Value(DateTime(2025, 2, 1, 10, 0)),
        duration: const Value(45),
        people: const Value('[]'),
        links: const Value('[]'),
        attachments: const Value('[]'),
      );

      await database.eventsDao.upsertEvent(event);
      
      var retrieved = await database.eventsDao.getEventById(1);
      expect(retrieved!.title, 'Original Title');

      // Update
      final updated = retrieved.copyWith(title: 'Updated Title');
      await database.eventsDao.updateEvent(updated);

      retrieved = await database.eventsDao.getEventById(1);
      expect(retrieved!.title, 'Updated Title');
    });

    test('batch insert works efficiently', () async {
      final events = List.generate(
        50,
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

      await database.eventsDao.insertEvents(events);
      final allEvents = await database.eventsDao.getAllEvents();

      expect(allEvents.length, 50);
    });
  });
}
