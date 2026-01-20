import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/datasources/local/database.dart';
import 'package:fosdem_flutter/data/datasources/local/tables/events_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('End-to-End Events Loading Tests', () {
    test('STEP 1: Can insert a single event', () async {
      print('🧪 Testing single event insert...');
      
      final event = EventsCompanion.insert(
        id: const Value(1),
        title: 'Test Event 1',
        track: 'Test Track',
        date: DateTime(2024, 2, 3),
        start: DateTime(2024, 2, 3, 10, 0),
        duration: 60,
        room: 'Room 1',
        people: '[]',
        links: '[]',
        attachments: '[]',
      );

      final insertedId = await database.eventsDao.upsertEvent(event);
      print('✅ Inserted event with ID: $insertedId');

      final allEvents = await database.eventsDao.getAllEvents();
      print('📊 Total events in DB: ${allEvents.length}');
      
      expect(allEvents.length, equals(1), reason: 'Should have 1 event after insert');
      expect(allEvents.first.title, equals('Test Event 1'));
      
      print('✅ STEP 1 PASSED\n');
    });

    test('STEP 2: Can insert multiple events in batch WITHOUT favorites', () async {
      print('🧪 Testing batch event insert (no favorites)...');
      
      final events = [
        EventsCompanion.insert(id: const Value(1), title: 'Event 1', track: 'Test Track', date: DateTime(2024, 2, 3), start: DateTime(2024, 2, 3, 10, 0), duration: 60, room: 'Room 1', people: '[]', links: '[]', attachments: '[]'),
        EventsCompanion.insert(id: const Value(2), title: 'Event 2', track: 'Test Track', date: DateTime(2024, 2, 3), start: DateTime(2024, 2, 3, 11, 0), duration: 60, room: 'Room 2', people: '[]', links: '[]', attachments: '[]'),
        EventsCompanion.insert(id: const Value(3), title: 'Event 3', track: 'Test Track', date: DateTime(2024, 2, 3), start: DateTime(2024, 2, 3, 12, 0), duration: 60, room: 'Room 3', people: '[]', links: '[]', attachments: '[]'),
      ];

      print('📤 Inserting ${events.length} events...');
      await database.eventsDao.insertEvents(events);

      final allEvents = await database.eventsDao.getAllEvents();
      print('📊 Total events in DB: ${allEvents.length}');
      
      expect(allEvents.length, equals(3), reason: 'Should have 3 events');
      
      print('✅ STEP 2 PASSED\n');
    });

    test('STEP 3: DIAGNOSTIC - Complete workflow', () async {
      print('\n🔬 COMPLETE WORKFLOW SIMULATION\n');
      print('=' * 60);
      
      // Step 1: Load events (no favorites)
      print('\n📱 SCENARIO 1: First load (no favorites)');
      print('-' * 60);
      final apiEvents = List.generate(10, (i) => EventsCompanion.insert(
        id: Value(i + 1),
        title: 'Event ${i + 1}',
        track: 'Test Track',
        date: DateTime(2024, 2, 3),
        start: DateTime(2024, 2, 3, 10, 0),
        duration: 60,
        room: 'Room ${i + 1}',
        people: '[]',
        links: '[]',
        attachments: '[]',
      ));

      print('📡 Loading ${apiEvents.length} events...');
      await database.eventsDao.insertEvents(apiEvents);
      
      var allEvents = await database.eventsDao.getAllEvents();
      print('✅ Database has ${allEvents.length} events');
      expect(allEvents.length, equals(10), reason: 'Should load all 10 events');

      // Step 2: User adds favorites
      print('\n⭐ SCENARIO 2: Add favorites');
      print('-' * 60);
      await database.eventsDao.setFavorite('5', true);
      
      var favorites = await database.eventsDao.getFavoriteEvents();
      print('✅ User has ${favorites.length} favorite(s)');
      expect(favorites.length, equals(1));

      // Step 3: Reload events (with favorites existing)
      print('\n🔄 SCENARIO 3: Reload events');
      print('-' * 60);
      final refreshEvents = List.generate(10, (i) => EventsCompanion.insert(
        id: Value(i + 1),
        title: 'Event ${i + 1} Updated',
        track: 'Test Track',
        date: DateTime(2024, 2, 3),
        start: DateTime(2024, 2, 3, 10, 0),
        duration: 60,
        room: 'Room ${i + 1}',
        people: '[]',
        links: '[]',
        attachments: '[]',
        isFavorite: const Value(false),
      ));

      print('📡 Reloading ${refreshEvents.length} events...');
      await database.eventsDao.insertEvents(refreshEvents);

      allEvents = await database.eventsDao.getAllEvents();
      print('📊 After reload: ${allEvents.length} events');
      expect(allEvents.length, equals(10), reason: 'Should still have 10 events');

      favorites = await database.eventsDao.getFavoriteEvents();
      print('⭐ After reload: ${favorites.length} favorite(s)');
      expect(favorites.length, equals(1), reason: 'Favorite should be preserved');

      print('\n' + '=' * 60);
      print('🎉 COMPLETE WORKFLOW PASSED!\n');
    });
  });
}
