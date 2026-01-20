import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import '../lib/data/datasources/local/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Debug: Check favorite functionality', () async {
    // Insert a test event
    final now = DateTime.now();
    final eventId = await database.eventsDao.insertEvent(EventsCompanion.insert(
      id: const Value(1),
      title: 'Test Event',
      track: 'Test Track',
      date: now,
      start: now,
      duration: 60,
      room: 'Test Room',
      abstract: const Value('Test abstract'),
      description: const Value('Test description'),
      people: '[]',
      links: '[]',
      attachments: '[]',
      isFavorite: const Value(false),
    ));

    print('Inserted event ID: $eventId');

    // Check if event exists
    final event = await database.eventsDao.getEventById(1);
    print('Event retrieved: ${event?.title}, isFavorite: ${event?.isFavorite}');

    // Add to favorites
    await database.eventsDao.updateEvent(
      event!.copyWith(isFavorite: true),
    );

    // Check if favorite was saved
    final updatedEvent = await database.eventsDao.getEventById(1);
    print('After update - isFavorite: ${updatedEvent?.isFavorite}');

    // Get all favorites
    final favorites = await database.eventsDao.getFavoriteEvents();
    print('Favorite events count: ${favorites.length}');
    
    if (favorites.isNotEmpty) {
      print('First favorite: ${favorites.first.title}');
    }

    expect(updatedEvent?.isFavorite, true);
    expect(favorites.length, 1);
  });
}
