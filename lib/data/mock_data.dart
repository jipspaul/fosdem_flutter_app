import 'datasources/local/database.dart';
import 'package:drift/drift.dart';

Future<void> seedMockData(AppDatabase database) async {
  // Add some mock events for testing
  final mockEvents = [
    EventsCompanion.insert(
      id: const Value(1),
      title: 'Welcome to FOSDEM 2025',
      subtitle: const Value('Opening Keynote'),
      abstract: const Value('Join us for the opening of FOSDEM 2025'),
      description: const Value('The opening keynote will set the stage for an amazing weekend of open source talks and networking.'),
      room: 'Janson',
      track: 'Keynotes',
      date: DateTime(2025, 2, 1),
      start: DateTime(2025, 2, 1, 10, 0),
      duration: 60,
      people: '[]',
      links: '[]',
      attachments: '[]',
    ),
    EventsCompanion.insert(
      id: const Value(2),
      title: 'State of Flutter',
      subtitle: const Value('Flutter Development'),
      abstract: const Value('Overview of Flutter in 2025'),
      description: const Value('Learn about the latest developments in Flutter and what\'s coming next.'),
      room: 'H.1301',
      track: 'Flutter',
      date: DateTime(2025, 2, 1),
      start: DateTime(2025, 2, 1, 11, 0),
      duration: 45,
      people: '[]',
      links: '[]',
      attachments: '[]',
    ),
    EventsCompanion.insert(
      id: const Value(3),
      title: 'Building Web Apps with Flutter',
      subtitle: const Value('Flutter Web'),
      abstract: const Value('Learn how to build production-ready web apps'),
      description: const Value('This talk covers best practices for building Flutter web applications.'),
      room: 'H.1302',
      track: 'Flutter',
      date: DateTime(2025, 2, 1),
      start: DateTime(2025, 2, 1, 14, 0),
      duration: 50,
      people: '[]',
      links: '[]',
      attachments: '[]',
    ),
    EventsCompanion.insert(
      id: const Value(4),
      title: 'Dart 4.0 and Beyond',
      subtitle: const Value('Dart Language'),
      abstract: const Value('Exploring the future of Dart'),
      description: const Value('Deep dive into Dart 4.0 features and roadmap.'),
      room: 'H.1308',
      track: 'Dart',
      date: DateTime(2025, 2, 2),
      start: DateTime(2025, 2, 2, 10, 30),
      duration: 45,
      people: '[]',
      links: '[]',
      attachments: '[]',
    ),
    EventsCompanion.insert(
      id: const Value(5),
      title: 'Building Mobile Apps at Scale',
      subtitle: const Value('Flutter Architecture'),
      abstract: const Value('Architecture patterns for large Flutter apps'),
      description: const Value('Learn about clean architecture, BLoC, and other patterns for scaling Flutter applications.'),
      room: 'H.1301',
      track: 'Flutter',
      date: DateTime(2025, 2, 2),
      start: DateTime(2025, 2, 2, 15, 0),
      duration: 45,
      people: '[]',
      links: '[]',
      attachments: '[]',
      isFavorite: const Value(true),
    ),
  ];

  for (final event in mockEvents) {
    try {
      await database.eventsDao.insertEvent(event);
    } catch (e) {
      // Ignore if already exists
      print('Event already exists or error: $e');
    }
  }

  print('Mock data seeded successfully!');
}
