import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:fosdem_flutter/data/repositories/events_repository_impl.dart';
import 'package:fosdem_flutter/data/datasources/local/database.dart';
import 'package:fosdem_flutter/data/datasources/remote/fosdem_api.dart';
import 'package:fosdem_flutter/domain/entities/event.dart';
import 'package:fosdem_flutter/data/models/event_model.dart';
import 'package:fosdem_flutter/core/error/failures.dart';

@GenerateMocks([FosdemApi])
import 'events_repository_test.mocks.dart';

void main() {
  late EventsRepositoryImpl repository;
  late MockAppDatabase mockDatabase;
  late MockFosdemApi mockApi;
  late MockEventsDao mockEventsDao;

  setUp(() {
    mockDatabase = MockAppDatabase();
    mockApi = MockFosdemApi();
    mockEventsDao = MockEventsDao();
    
    when(mockDatabase.eventsDao).thenReturn(mockEventsDao);
    
    repository = EventsRepositoryImpl(
      database: mockDatabase,
      api: mockApi,
    );
  });

  group('EventsRepository', () {
    final testEvent = Event(
      id: 1,
      title: 'Test Event',
      subtitle: 'Test Subtitle',
      abstract: 'Test abstract',
      description: 'Test description',
      track: 'Test Track',
      date: DateTime(2025, 2, 1),
      start: DateTime(2025, 2, 1, 10, 0),
      duration: 30,
      room: 'H.2215',
      people: const [],
      links: const [],
      attachments: const [],
    );

    final testEventModel = EventModel.fromEntity(testEvent);

    group('getEvents', () {
      test('should return list of events from database', () async {
        // Arrange
        when(mockEventsDao.getAllEvents(limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenAnswer((_) async => [testEventModel]);

        // Act
        final result = await repository.getEvents();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (events) {
            expect(events.length, 1);
            expect(events.first.id, testEvent.id);
            expect(events.first.title, testEvent.title);
          },
        );
        verify(mockEventsDao.getAllEvents(limit: anyNamed('limit'), offset: anyNamed('offset')));
      });

      test('should return failure when database throws', () async {
        // Arrange
        when(mockEventsDao.getAllEvents(limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getEvents();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      });

      test('should respect limit and offset parameters', () async {
        // Arrange
        when(mockEventsDao.getAllEvents(limit: 10, offset: 5))
            .thenAnswer((_) async => [testEventModel]);

        // Act
        await repository.getEvents(limit: 10, offset: 5);

        // Assert
        verify(mockEventsDao.getAllEvents(limit: 10, offset: 5));
      });
    });

    group('getEventById', () {
      test('should return event when found', () async {
        // Arrange
        when(mockEventsDao.getEventById('1'))
            .thenAnswer((_) async => testEventModel);

        // Act
        final result = await repository.getEventById('1');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (event) {
            expect(event.id, testEvent.id);
            expect(event.title, testEvent.title);
          },
        );
      });

      test('should return failure when event not found', () async {
        // Arrange
        when(mockEventsDao.getEventById('1'))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getEventById('1');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('not found'));
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('searchEvents', () {
      test('should return filtered events', () async {
        // Arrange
        when(mockEventsDao.searchEvents('test'))
            .thenAnswer((_) async => [testEventModel]);

        // Act
        final result = await repository.searchEvents('test');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (events) => expect(events.length, 1),
        );
      });

      test('should return empty list when no matches', () async {
        // Arrange
        when(mockEventsDao.searchEvents('nonexistent'))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.searchEvents('nonexistent');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (events) => expect(events.isEmpty, true),
        );
      });
    });

    group('getEventsByTrack', () {
      test('should return events for track', () async {
        // Arrange
        when(mockEventsDao.getEventsByTrack('track1'))
            .thenAnswer((_) async => [testEventModel]);

        // Act
        final result = await repository.getEventsByTrack('track1');

        // Assert
        expect(result.isRight(), true);
        verify(mockEventsDao.getEventsByTrack('track1'));
      });
    });

    group('getEventsByDate', () {
      test('should return events for date range', () async {
        // Arrange
        final startDate = DateTime(2025, 2, 1);
        final endDate = DateTime(2025, 2, 2);
        when(mockEventsDao.getEventsByDateRange(startDate, endDate))
            .thenAnswer((_) async => [testEventModel]);

        // Act
        final result = await repository.getEventsByDate(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result.isRight(), true);
        verify(mockEventsDao.getEventsByDateRange(startDate, endDate));
      });

      test('should use start date + 1 day when end date not provided', () async {
        // Arrange
        final startDate = DateTime(2025, 2, 1);
        when(mockEventsDao.getEventsByDateRange(any, any))
            .thenAnswer((_) async => [testEventModel]);

        // Act
        await repository.getEventsByDate(startDate: startDate);

        // Assert
        verify(mockEventsDao.getEventsByDateRange(
          startDate,
          startDate.add(const Duration(days: 1)),
        ));
      });
    });

    group('getEventsByRoom', () {
      test('should return events for room', () async {
        // Arrange
        when(mockEventsDao.getEventsByRoom('H.2215'))
            .thenAnswer((_) async => [testEventModel]);

        // Act
        final result = await repository.getEventsByRoom('H.2215');

        // Assert
        expect(result.isRight(), true);
        verify(mockEventsDao.getEventsByRoom('H.2215'));
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite status', () async {
        // Arrange
        when(mockEventsDao.isFavorite('1'))
            .thenAnswer((_) async => false);
        when(mockEventsDao.setFavorite('1', true))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.toggleFavorite('1');

        // Assert
        expect(result.isRight(), true);
        verify(mockEventsDao.isFavorite('1'));
        verify(mockEventsDao.setFavorite('1', true));
      });

      test('should unfavorite when already favorited', () async {
        // Arrange
        when(mockEventsDao.isFavorite('1'))
            .thenAnswer((_) async => true);
        when(mockEventsDao.setFavorite('1', false))
            .thenAnswer((_) async {});

        // Act
        await repository.toggleFavorite('1');

        // Assert
        verify(mockEventsDao.setFavorite('1', false));
      });
    });

    group('isFavorite', () {
      test('should return favorite status', () async {
        // Arrange
        when(mockEventsDao.isFavorite('1'))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.isFavorite('1');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (isFav) => expect(isFav, true),
        );
      });
    });

    group('getFavoriteEvents', () {
      test('should return favorited events', () async {
        // Arrange
        when(mockEventsDao.getFavoriteEvents())
            .thenAnswer((_) async => [testEventModel]);

        // Act
        final result = await repository.getFavoriteEvents();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (events) => expect(events.length, 1),
        );
      });
    });

    group('clearCache', () {
      test('should clear all events from database', () async {
        // Arrange
        when(mockEventsDao.deleteAllEvents())
            .thenAnswer((_) async {});

        // Act
        final result = await repository.clearCache();

        // Assert
        expect(result.isRight(), true);
        verify(mockEventsDao.deleteAllEvents());
      });
    });
  });
}
