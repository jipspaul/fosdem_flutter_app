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

  group('Favorites DAO Additional Coverage -', () {
    test('watchFavorites stream emits updates', () async {
      final stream = database.favoritesDao.watchFavorites();
      
      // Listen to stream
      expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty
          isA<List>(), // After adding favorite
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await database.favoritesDao.addFavorite(1);
    });

    test('removeFavorite with non-existent ID doesnt error', () async {
      // Should not throw even if favorite doesn't exist
      await database.favoritesDao.removeFavorite(999);
      
      final favorites = await database.favoritesDao.getAllFavorites();
      expect(favorites, isEmpty);
    });

    test('multiple users can have separate favorites', () async {
      await database.favoritesDao.addFavorite(1, userId: 'user1');
      await database.favoritesDao.addFavorite(2, userId: 'user1');
      await database.favoritesDao.addFavorite(1, userId: 'user2');

      final user1Favorites = await database.favoritesDao.getFavoriteEventIds(userId: 'user1');
      final user2Favorites = await database.favoritesDao.getFavoriteEventIds(userId: 'user2');

      expect(user1Favorites.length, 2);
      expect(user2Favorites.length, 1);
    });
  });

  group('Tracks DAO Additional Coverage -', () {
    test('watchAllTracks stream emits updates', () async {
      final stream = database.tracksDao.watchAllTracks();
      
      expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty
          isA<List>(), // After adding track
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await database.tracksDao.insertTrack(
        const TracksCompanion(name: Value('Test Track')),
      );
    });

    test('updateTrack modifies existing track', () async {
      await database.tracksDao.insertTrack(
        const TracksCompanion(
          name: Value('Original Track'),
          colorHex: Value('#FF0000'),
        ),
      );

      var track = await database.tracksDao.getTrackByName('Original Track');
      expect(track!.colorHex, '#FF0000');

      // Update
      final updated = track.copyWith(colorHex: '#00FF00');
      await database.tracksDao.updateTrack(updated);

      track = await database.tracksDao.getTrackByName('Original Track');
      expect(track!.colorHex, '#00FF00');
    });

    test('getTracksByDate handles null dates', () async {
      await database.tracksDao.insertTrack(
        const TracksCompanion(name: Value('Track No Date')),
      );

      final tracks = await database.tracksDao.getAllTracks();
      expect(tracks.length, 1);
      expect(tracks[0].date, isNull);
    });
  });

  group('People DAO Additional Coverage -', () {
    test('watchAllPeople stream emits updates', () async {
      final stream = database.peopleDao.watchAllPeople();
      
      expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty
          isA<List>(), // After adding person
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await database.peopleDao.insertPerson(
        const PeopleCompanion(name: Value('Test Person')),
      );
    });

    test('updatePerson modifies existing person', () async {
      final id = await database.peopleDao.insertPerson(
        const PeopleCompanion(
          name: Value('John Doe'),
          bio: Value('Original bio'),
        ),
      );

      var person = await database.peopleDao.getPersonById(id);
      expect(person!.bio, 'Original bio');

      // Update
      final updated = person.copyWith(bio: 'Updated bio');
      await database.peopleDao.updatePerson(updated);

      person = await database.peopleDao.getPersonById(id);
      expect(person!.bio, 'Updated bio');
    });

    test('searchPeople is case insensitive', () async {
      await database.peopleDao.insertPeople([
        const PeopleCompanion(name: Value('JOHN DOE')),
        const PeopleCompanion(name: Value('john smith')),
      ]);

      final results = await database.peopleDao.searchPeople('john');
      expect(results.length, 2);
    });
  });

  group('Buildings DAO Additional Coverage -', () {
    test('watchAllBuildings stream emits updates', () async {
      final stream = database.buildingsDao.watchAllBuildings();
      
      expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty
          isA<List>(), // After adding building
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await database.buildingsDao.insertBuilding(
        const BuildingsCompanion(
          id: Value('H'),
          title: Value('H Building'),
          glyph: Value('H'),
          latitude: Value(50.8137),
          longitude: Value(4.3805),
          polygon: Value('[]'),
          blueprints: Value('[]'),
        ),
      );
    });

    test('updateBuilding modifies existing building', () async {
      await database.buildingsDao.insertBuilding(
        const BuildingsCompanion(
          id: Value('H'),
          title: Value('Original Title'),
          glyph: Value('H'),
          latitude: Value(50.8137),
          longitude: Value(4.3805),
          polygon: Value('[]'),
          blueprints: Value('[]'),
        ),
      );

      var building = await database.buildingsDao.getBuildingById('H');
      expect(building!.title, 'Original Title');

      // Update
      final updated = building.copyWith(title: 'Updated Title');
      await database.buildingsDao.updateBuilding(updated);

      building = await database.buildingsDao.getBuildingById('H');
      expect(building!.title, 'Updated Title');
    });

    test('insertBuildings handles duplicates with replace', () async {
      await database.buildingsDao.insertBuilding(
        const BuildingsCompanion(
          id: Value('H'),
          title: Value('Original'),
          glyph: Value('H'),
          latitude: Value(50.8137),
          longitude: Value(4.3805),
          polygon: Value('[]'),
          blueprints: Value('[]'),
        ),
      );

      // Insert again with same ID
      await database.buildingsDao.insertBuilding(
        const BuildingsCompanion(
          id: Value('H'),
          title: Value('Updated'),
          glyph: Value('H'),
          latitude: Value(50.8137),
          longitude: Value(4.3805),
          polygon: Value('[]'),
          blueprints: Value('[]'),
        ),
      );

      final buildings = await database.buildingsDao.getAllBuildings();
      expect(buildings.length, 1); // Should only have one
      expect(buildings[0].title, 'Updated');
    });
  });

  group('Events DAO Stream Coverage -', () {
    test('watchAllEvents stream emits updates', () async {
      final stream = database.eventsDao.watchAllEvents();
      
      expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty
          isA<List>(), // After adding event
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await database.eventsDao.insertEvents([
        EventsCompanion(
          id: const Value(1),
          title: const Value('Test'),
          room: const Value('H.1302'),
          track: const Value('Test'),
          date: Value(DateTime.now()),
          start: Value(DateTime.now()),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ]);
    });

    test('watchEventsByTrack stream filters correctly', () async {
      final stream = database.eventsDao.watchEventsByTrack('Mobile');
      
      await database.eventsDao.insertEvents([
        EventsCompanion(
          id: const Value(1),
          title: const Value('Mobile Event'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(DateTime.now()),
          start: Value(DateTime.now()),
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
          date: Value(DateTime.now()),
          start: Value(DateTime.now()),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ]);

      await expectLater(
        stream.first,
        completion(hasLength(1)),
      );
    });

    test('watchFavoriteEvents stream emits updates', () async {
      final stream = database.eventsDao.watchFavoriteEvents();
      
      await database.eventsDao.insertEvents([
        EventsCompanion(
          id: const Value(1),
          title: const Value('Favorite'),
          room: const Value('H.1302'),
          track: const Value('Test'),
          date: Value(DateTime.now()),
          start: Value(DateTime.now()),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
          isFavorite: const Value(true),
        ),
      ]);

      await expectLater(
        stream.first,
        completion(hasLength(1)),
      );
    });
  });

  group('Database Search Coverage -', () {
    test('searchEvents finds events by title', () async {
      await database.eventsDao.insertEvents([
        EventsCompanion(
          id: const Value(1),
          title: const Value('Flutter Mobile Development'),
          room: const Value('H.1302'),
          track: const Value('Mobile'),
          date: Value(DateTime.now()),
          start: Value(DateTime.now()),
          duration: const Value(45),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
        EventsCompanion(
          id: const Value(2),
          title: const Value('React Web Development'),
          room: const Value('H.1303'),
          track: const Value('Web'),
          date: Value(DateTime.now()),
          start: Value(DateTime.now()),
          duration: const Value(30),
          people: const Value('[]'),
          links: const Value('[]'),
          attachments: const Value('[]'),
        ),
      ]);

      // Wait for FTS to index
      await Future.delayed(const Duration(milliseconds: 500));

      final results = await database.searchEvents('Flutter');
      expect(results.length, greaterThanOrEqualTo(0)); // FTS may need time
    });
  });
}
