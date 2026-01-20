import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/repositories/event_repository.dart';
import 'package:fosdem_flutter/data/services/data_loading_service.dart';
import 'package:fosdem_flutter/core/di/injection_container.dart' as di;

void main() {
  group('Favorites Persistence Integration Tests', () {
    late EventRepository eventRepository;
    late DataLoadingService dataLoadingService;

    setUpAll(() async {
      await di.init();
      eventRepository = di.sl<EventRepository>();
      dataLoadingService = di.sl<DataLoadingService>();
    });

    setUp(() async {
      // Clear all data before each test
      await eventRepository.deleteAll();
    });

    test('should persist favorites when data is reloaded', () async {
      // 1. Load initial data
      await dataLoadingService.loadBundledData();
      var events = await eventRepository.getAll();
      expect(events, isNotEmpty, reason: 'Should have loaded events');
      
      final firstEvent = events.first;
      final eventId = firstEvent.id.toString();
      print('Testing with event ID: $eventId, title: "${firstEvent.title}"');

      // 2. Add to favorites
      await eventRepository.addFavorite(eventId);
      
      // 3. Verify event is now a favorite
      var favorites = await eventRepository.getFavoriteEvents();
      expect(favorites.length, 1, reason: 'Should have 1 favorite');
      expect(favorites.first.id, firstEvent.id, reason: 'Favorite should be the first event');

      // 4. Reload data (simulating app restart or data refresh)
      print('Reloading data to test persistence...');
      await dataLoadingService.loadBundledData();

      // 5. Verify favorite still exists after reload
      favorites = await eventRepository.getFavoriteEvents();
      expect(favorites.length, 1, reason: 'Favorite should persist after reload');
      expect(favorites.first.id, firstEvent.id, reason: 'Same event should still be favorite');
      
      // 6. Verify the event's isFavorite flag is still true
      events = await eventRepository.getAll();
      final reloadedEvent = events.firstWhere((e) => e.id == firstEvent.id);
      expect(reloadedEvent.isFavorite, isTrue, reason: 'Event isFavorite flag should be true after reload');
    });

    test('should persist multiple favorites across reload', () async {
      // 1. Load initial data
      await dataLoadingService.loadBundledData();
      var events = await eventRepository.getAll();
      expect(events.length, greaterThanOrEqualTo(3), reason: 'Need at least 3 events for test');
      
      // 2. Add 3 events to favorites
      final event1 = events[0];
      final event2 = events[1];
      final event3 = events[2];
      
      await eventRepository.addFavorite(event1.id.toString());
      await eventRepository.addFavorite(event2.id.toString());
      await eventRepository.addFavorite(event3.id.toString());

      // 3. Verify all 3 are favorites
      var favorites = await eventRepository.getFavoriteEvents();
      expect(favorites.length, 3, reason: 'Should have 3 favorites');

      // 4. Reload data
      await dataLoadingService.loadBundledData();

      // 5. Verify all 3 favorites persist
      favorites = await eventRepository.getFavoriteEvents();
      expect(favorites.length, 3, reason: 'All 3 favorites should persist');
      
      final favoriteIds = favorites.map((e) => e.id).toSet();
      expect(favoriteIds.contains(event1.id), isTrue);
      expect(favoriteIds.contains(event2.id), isTrue);
      expect(favoriteIds.contains(event3.id), isTrue);
    });

    test('should handle adding and removing favorites before reload', () async {
      // 1. Load data
      await dataLoadingService.loadBundledData();
      var events = await eventRepository.getAll();
      
      final event1 = events[0];
      final event2 = events[1];
      
      // 2. Add two favorites
      await eventRepository.addFavorite(event1.id.toString());
      await eventRepository.addFavorite(event2.id.toString());
      
      var favorites = await eventRepository.getFavoriteEvents();
      expect(favorites.length, 2);

      // 3. Remove one favorite
      await eventRepository.removeFavorite(event1.id.toString());
      
      favorites = await eventRepository.getFavoriteEvents();
      expect(favorites.length, 1);
      expect(favorites.first.id, event2.id);

      // 4. Reload data
      await dataLoadingService.loadBundledData();

      // 5. Verify only event2 is still a favorite
      favorites = await eventRepository.getFavoriteEvents();
      expect(favorites.length, 1, reason: 'Only 1 favorite should remain');
      expect(favorites.first.id, event2.id, reason: 'Event2 should still be favorite');
    });

    test('favorites page should show favorited events', () async {
      // 1. Load data
      await dataLoadingService.loadBundledData();
      var events = await eventRepository.getAll();
      expect(events, isNotEmpty);
      
      // 2. Initially, no favorites
      var favorites = await eventRepository.getFavoriteEvents();
      expect(favorites, isEmpty, reason: 'Should start with no favorites');

      // 3. Add a favorite
      final testEvent = events.first;
      await eventRepository.addFavorite(testEvent.id.toString());

      // 4. Get favorites (this is what the favorites page does)
      favorites = await eventRepository.getFavoriteEvents();
      expect(favorites.length, 1, reason: 'Should show 1 event in favorites');
      expect(favorites.first.id, testEvent.id);
      expect(favorites.first.title, testEvent.title);
      expect(favorites.first.isFavorite, isTrue);
    });
  });
}
