import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import '../../lib/data/datasources/local/database.dart';
import '../../lib/data/repositories/event_repository.dart';
import '../../lib/data/datasources/remote/fosdem_api.dart';
import '../../lib/domain/entities/event.dart';

void main() {
  group('Favorites Debug Tests', () {
    late AppDatabase database;
    late EventRepository repository;

    setUp(() {
      database = AppDatabase.test(NativeDatabase.memory());
      repository = EventRepository(
        database: database,
        api: FosdemApi(dio: null), // Mock or null for testing
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('Step 1: Add event and mark as favorite', () async {
      print('\n=== TEST: Add event and mark as favorite ===');
      
      // Create a test event
      final event = Event(
        id: 1,
        title: 'Test Event',
        subtitle: 'Test Subtitle',
        abstract: 'Test Abstract',
        description: 'Test Description',
        room: 'Room 1',
        track: 'Track 1',
        date: DateTime(2025, 2, 1),
        start: DateTime(2025, 2, 1, 10, 0),
        duration: 60,
        url: 'https://test.com',
        people: [],
        links: [],
        attachments: [],
      );

      // Insert event
      print('1. Inserting event...');
      await repository.create(event);
      
      // Verify event exists
      final allEvents = await database.eventsDao.getAllEvents();
      print('2. Total events in DB: ${allEvents.length}');
      expect(allEvents.length, 1);
      print('   Event: ${allEvents[0].title}, isFavorite: ${allEvents[0].isFavorite}');
      
      // Add to favorites
      print('3. Adding to favorites...');
      await repository.addFavorite('1');
      
      // Check if favorite was set
      final eventAfterFavorite = await database.eventsDao.getEventById('1');
      print('4. After addFavorite - isFavorite: ${eventAfterFavorite?.isFavorite}');
      expect(eventAfterFavorite?.isFavorite, true);
      
      // Get favorites
      print('5. Getting favorite events...');
      final favorites = await repository.getFavoriteEvents();
      print('6. Favorites count: ${favorites.length}');
      
      if (favorites.isEmpty) {
        print('   ❌ PROBLEM: No favorites found!');
        print('   ❌ Database query returned no results');
        
        // Debug: Check raw database
        final allEventsAgain = await database.eventsDao.getAllEvents();
        print('   DEBUG: Total events: ${allEventsAgain.length}');
        for (final e in allEventsAgain) {
          print('   DEBUG: Event ${e.id} - isFavorite: ${e.isFavorite}');
        }
      } else {
        print('   ✅ SUCCESS: Found ${favorites.length} favorite(s)');
        for (final fav in favorites) {
          print('   ✅ Favorite: ${fav.title}');
        }
      }
      
      expect(favorites.length, 1);
      expect(favorites[0].title, 'Test Event');
    });

    test('Step 2: Check getFavoriteEvents query', () async {
      print('\n=== TEST: Check getFavoriteEvents query ===');
      
      // Insert events directly with favorite flag
      await database.eventsDao.insertEvent(EventsCompanion.insert(
        id: const Value(10),
        title: 'Favorite 1',
        subtitle: const Value('Sub 1'),
        abstract: const Value(''),
        description: const Value(''),
        room: 'Room',
        track: 'Track',
        date: DateTime(2025, 2, 1),
        start: DateTime(2025, 2, 1, 10, 0),
        duration: 60,
        people: '[]',
        links: '[]',
        attachments: '[]',
        isFavorite: const Value(true),  // Set favorite directly
      ));

      await database.eventsDao.insertEvent(EventsCompanion.insert(
        id: const Value(11),
        title: 'Not Favorite',
        subtitle: const Value('Sub 2'),
        abstract: const Value(''),
        description: const Value(''),
        room: 'Room',
        track: 'Track',
        date: DateTime(2025, 2, 1),
        start: DateTime(2025, 2, 1, 11, 0),
        duration: 60,
        people: '[]',
        links: '[]',
        attachments: '[]',
        isFavorite: const Value(false),  // Not favorite
      ));

      print('1. Inserted 2 events (1 favorite, 1 not)');
      
      // Check all events
      final allEvents = await database.eventsDao.getAllEvents();
      print('2. All events in DB:');
      for (final e in allEvents) {
        print('   - Event ${e.id}: ${e.title}, isFavorite=${e.isFavorite}');
      }
      
      // Get favorites using DAO
      print('3. Getting favorites using DAO...');
      final favoriteEventsDao = await database.eventsDao.getFavoriteEvents();
      print('4. DAO returned ${favoriteEventsDao.length} favorites');
      
      // Get favorites using Repository
      print('5. Getting favorites using Repository...');
      final favoriteEventsRepo = await repository.getFavoriteEvents();
      print('6. Repository returned ${favoriteEventsRepo.length} favorites');
      
      expect(favoriteEventsDao.length, 1);
      expect(favoriteEventsRepo.length, 1);
      expect(favoriteEventsRepo[0].title, 'Favorite 1');
    });

    test('Step 3: Toggle favorite and check persistence', () async {
      print('\n=== TEST: Toggle favorite and check persistence ===');
      
      // Create event
      final event = Event(
        id: 20,
        title: 'Toggle Test',
        subtitle: '',
        abstract: '',
        description: '',
        room: 'Room',
        track: 'Track',
        date: DateTime(2025, 2, 1),
        start: DateTime(2025, 2, 1, 10, 0),
        duration: 60,
        url: '',
        people: [],
        links: [],
        attachments: [],
      );

      await repository.create(event);
      print('1. Created event ID 20');
      
      // Check initial state
      var isFav = await database.eventsDao.isFavorite('20');
      print('2. Initial isFavorite: $isFav');
      expect(isFav, false);
      
      // Add to favorites
      print('3. Adding to favorites...');
      await repository.addFavorite('20');
      
      isFav = await database.eventsDao.isFavorite('20');
      print('4. After addFavorite: $isFav');
      expect(isFav, true);
      
      // Check it appears in favorites list
      var favorites = await repository.getFavoriteEvents();
      print('5. Favorites list has ${favorites.length} items');
      expect(favorites.length, 1);
      
      // Remove from favorites
      print('6. Removing from favorites...');
      await repository.removeFavorite('20');
      
      isFav = await database.eventsDao.isFavorite('20');
      print('7. After removeFavorite: $isFav');
      expect(isFav, false);
      
      // Check it's gone from favorites list
      favorites = await repository.getFavoriteEvents();
      print('8. Favorites list has ${favorites.length} items');
      expect(favorites.length, 0);
      
      print('✅ Toggle test passed!');
    });
  });
}
