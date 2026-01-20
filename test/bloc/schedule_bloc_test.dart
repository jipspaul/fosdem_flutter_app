import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fosdem_flutter/presentation/bloc/schedule/schedule_bloc.dart';
import 'package:fosdem_flutter/data/repositories/event_repository.dart';
import 'package:fosdem_flutter/domain/entities/event_domain.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
  });

  group('ScheduleBloc', () {
    final testEvents = [
      EventDomain(
        id: 1,
        title: 'Test Talk',
        subtitle: 'A test subtitle',
        track: 'Testing',
        type: 'lecture',
        startTime: DateTime(2025, 2, 1, 10, 0),
        endTime: DateTime(2025, 2, 1, 11, 0),
        duration: 60,
        room: 'Janson',
        abstract: 'Test abstract',
        description: 'Test description',
        url: null,
        day: 1,
        isFavorite: false,
        isNotified: false,
      ),
    ];

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [loading, loaded] when LoadSchedule succeeds',
      build: () {
        when(() => mockRepository.getEvents())
            .thenAnswer((_) async => testEvents);
        return ScheduleBloc(eventRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadSchedule()),
      expect: () => [
        const ScheduleLoading(),
        ScheduleLoaded(events: testEvents),
      ],
      verify: (_) {
        verify(() => mockRepository.getEvents()).called(1);
      },
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [loading, error] when LoadSchedule fails',
      build: () {
        when(() => mockRepository.getEvents())
            .thenThrow(Exception('Failed to load'));
        return ScheduleBloc(eventRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadSchedule()),
      expect: () => [
        const ScheduleLoading(),
        ScheduleError('Failed to load schedule: Exception: Failed to load'),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'filters events by track',
      build: () {
        when(() => mockRepository.getEventsByTrack(any()))
            .thenAnswer((_) async => testEvents);
        return ScheduleBloc(eventRepository: mockRepository);
      },
      seed: () => ScheduleLoaded(events: testEvents),
      act: (bloc) => bloc.add(FilterByTrack('Testing')),
      expect: () => [
        ScheduleLoaded(
          events: testEvents,
          selectedTrack: 'Testing',
        ),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'searches events',
      build: () {
        when(() => mockRepository.searchEvents(any()))
            .thenAnswer((_) async => testEvents);
        return ScheduleBloc(eventRepository: mockRepository);
      },
      seed: () => ScheduleLoaded(events: testEvents),
      act: (bloc) => bloc.add(SearchEvents('Test')),
      expect: () => [
        ScheduleLoaded(
          events: testEvents,
          searchQuery: 'Test',
        ),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'refreshes schedule successfully',
      build: () {
        when(() => mockRepository.syncEvents())
            .thenAnswer((_) async => {});
        when(() => mockRepository.getEvents())
            .thenAnswer((_) async => testEvents);
        return ScheduleBloc(eventRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const RefreshSchedule()),
      expect: () => [
        const ScheduleLoading(),
        ScheduleLoaded(events: testEvents),
      ],
      verify: (_) {
        verify(() => mockRepository.syncEvents()).called(1);
        verify(() => mockRepository.getEvents()).called(1);
      },
    );
  });
}
