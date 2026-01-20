import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fosdem_flutter/features/search/bloc/search_bloc.dart';
import 'package:fosdem_flutter/features/search/bloc/search_event.dart';
import 'package:fosdem_flutter/features/search/bloc/search_state.dart';
import 'package:fosdem_flutter/data/repositories/schedule_repository.dart';
import 'package:fosdem_flutter/domain/entities/event_entity.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;

  setUp(() {
    mockRepository = MockScheduleRepository();
  });

  group('SearchBloc', () {
    final testEvents = [
      EventEntity(
        id: 1,
        guid: 'event1',
        date: DateTime(2025, 2, 1, 10, 0),
        start: '10:00',
        duration: '01:00',
        room: 'Janson',
        slug: 'flutter-talk',
        title: 'Flutter Development',
        subtitle: 'Modern mobile apps',
        track: 'Mobile',
        type: 'lecture',
        language: 'en',
        abstract: 'Flutter abstract',
        description: 'Flutter description',
        persons: [],
        links: [],
        attachments: [],
      ),
      EventEntity(
        id: 2,
        guid: 'event2',
        date: DateTime(2025, 2, 1, 14, 0),
        start: '14:00',
        duration: '00:45',
        room: 'K.1.105',
        slug: 'rust-talk',
        title: 'Rust Programming',
        subtitle: 'Systems programming',
        track: 'Systems',
        type: 'lecture',
        language: 'en',
        abstract: 'Rust abstract',
        description: 'Rust description',
        persons: [],
        links: [],
        attachments: [],
      ),
    ];

    blocTest<SearchBloc, SearchState>(
      'emits results when search query is provided',
      build: () {
        when(() => mockRepository.searchEvents(any()))
            .thenAnswer((_) async => [testEvents[0]]);
        return SearchBloc(scheduleRepository: mockRepository);
      },
      act: (bloc) => bloc.add(SearchQueryChanged('Flutter')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'Flutter'),
        SearchState(
          status: SearchStatus.loaded,
          query: 'Flutter',
          results: [testEvents[0]],
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.searchEvents('Flutter')).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'emits empty state when query is cleared',
      build: () => SearchBloc(scheduleRepository: mockRepository),
      seed: () => SearchState(
        status: SearchStatus.loaded,
        query: 'Flutter',
        results: [testEvents[0]],
      ),
      act: (bloc) => bloc.add(SearchQueryChanged('')),
      expect: () => [
        const SearchState(status: SearchStatus.initial, query: ''),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'debounces rapid query changes',
      build: () {
        when(() => mockRepository.searchEvents(any()))
            .thenAnswer((_) async => testEvents);
        return SearchBloc(scheduleRepository: mockRepository);
      },
      act: (bloc) {
        bloc.add(SearchQueryChanged('F'));
        bloc.add(SearchQueryChanged('Fl'));
        bloc.add(SearchQueryChanged('Flu'));
        bloc.add(SearchQueryChanged('Flut'));
        bloc.add(SearchQueryChanged('Flutter'));
      },
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'Flutter'),
        SearchState(
          status: SearchStatus.loaded,
          query: 'Flutter',
          results: testEvents,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.searchEvents('Flutter')).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'emits error when search fails',
      build: () {
        when(() => mockRepository.searchEvents(any()))
            .thenThrow(Exception('Search failed'));
        return SearchBloc(scheduleRepository: mockRepository);
      },
      act: (bloc) => bloc.add(SearchQueryChanged('Flutter')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'Flutter'),
        const SearchState(
          status: SearchStatus.error,
          query: 'Flutter',
          errorMessage: 'Exception: Search failed',
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'clears search results',
      build: () => SearchBloc(scheduleRepository: mockRepository),
      seed: () => SearchState(
        status: SearchStatus.loaded,
        query: 'Flutter',
        results: testEvents,
      ),
      act: (bloc) => bloc.add(ClearSearch()),
      expect: () => [
        const SearchState(status: SearchStatus.initial),
      ],
    );
  });
}
