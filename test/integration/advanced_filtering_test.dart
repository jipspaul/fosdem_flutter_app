import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/features/filters/models/event_filter.dart';
import 'package:fosdem_flutter/features/filters/models/filter_criterion.dart';
import 'package:fosdem_flutter/features/filters/bloc/filter_bloc.dart';
import 'package:fosdem_flutter/features/filters/services/filter_persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fosdem_flutter/data/datasources/local/database.dart';
import 'package:drift/native.dart';

// Mock Event class for testing
class MockEvent {
  final int id;
  final String title;
  final DateTime start;
  final Duration duration;
  final String room;
  final String track;
  final String abstract;
  final String description;

  const MockEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.duration,
    required this.room,
    required this.track,
    required this.abstract,
    required this.description,
  });
}

void main() {
  group('Advanced Filtering Integration Tests', () {
    late FilterBloc filterBloc;
    late FilterPersistenceService persistenceService;
    late AppDatabase database;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      persistenceService = FilterPersistenceService(prefs);
      database = AppDatabase.test(NativeDatabase.memory());
      filterBloc = FilterBloc(
        persistenceService: persistenceService,
        database: database,
      );
    });

    tearDown(() {
      filterBloc.close();
    });

    test('Should start with empty filters', () {
      expect(filterBloc.state, isA<FilterInitial>());
    });

    test('Should add and apply text filter', () async {
      final filter = EventFilter(
        type: FilterType.text,
        criterion: TextCriterion(query: 'rust'),
      );

      filterBloc.add(AddFilter(filter));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(filterBloc.state, isA<FilterApplied>());
      final state = filterBloc.state as FilterApplied;
      expect(state.filters.length, 1);
      expect(state.filters.first.type, FilterType.text);
    });

    test('Should filter events by text', () async {
      final events = [
        MockEvent(
          id: 1,
          title: 'Rust Programming',
          start: MockDateTime(2025, 2, 1, 10, 0),
          duration: Duration(hours: 1),
          room: 'K.1.105',
          track: 'Rust',
          abstract: 'Learn Rust',
          description: 'Advanced Rust programming',
        ),
        MockEvent(
          id: 2,
          title: 'Python Basics',
          start: MockDateTime(2025, 2, 1, 11, 0),
          duration: Duration(hours: 1),
          room: 'K.1.105',
          track: 'Python',
          abstract: 'Learn Python',
          description: 'Python for beginners',
        ),
      ];

      final filter = EventFilter(
        type: FilterType.text,
        criterion: TextCriterion(query: 'rust'),
      );

      filterBloc.add(AddFilter(filter));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = filterBloc.state as FilterApplied;
      final filtered = state.applyFilters(events);

      expect(filtered.length, 1);
      expect(filtered.first.title, 'Rust Programming');
    });

    test('Should remove filter', () async {
      final filter = EventFilter(
        type: FilterType.text,
        criterion: TextCriterion(query: 'rust'),
      );

      filterBloc.add(AddFilter(filter));
      await Future.delayed(const Duration(milliseconds: 100));

      expect((filterBloc.state as FilterApplied).filters.length, 1);

      filterBloc.add(RemoveFilter(FilterType.text));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = filterBloc.state as FilterApplied;
      expect(state.filters.length, 0);
    });

    test('Should clear all filters', () async {
      filterBloc.add(AddFilter(EventFilter(
        type: FilterType.text,
        criterion: TextCriterion(query: 'rust'),
      )));
      await Future.delayed(const Duration(milliseconds: 100));

      filterBloc.add(AddFilter(EventFilter(
        type: FilterType.track,
        criterion: TrackCriterion(tracks: ['Rust']),
      )));
      await Future.delayed(const Duration(milliseconds: 100));

      expect((filterBloc.state as FilterApplied).filters.length, 2);

      filterBloc.add(ClearFilters());
      await Future.delayed(const Duration(milliseconds: 100));

      final state = filterBloc.state as FilterApplied;
      expect(state.filters.length, 0);
    });

    test('Should persist and load filters', () async {
      final filter = EventFilter(
        type: FilterType.track,
        criterion: TrackCriterion(tracks: ['Rust', 'Python']),
      );

      filterBloc.add(AddFilter(filter));
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new bloc to simulate app restart
      final newBloc = FilterBloc(
        persistenceService: persistenceService,
        database: database,
      );
      newBloc.add(LoadSavedFilters());
      await Future.delayed(const Duration(milliseconds: 100));

      final state = newBloc.state as FilterApplied;
      expect(state.filters.length, 1);
      expect(state.filters.first.type, FilterType.track);

      newBloc.close();
    });
  });
}

// Helper class for creating DateTime in const context
class MockDateTime extends DateTime {
  MockDateTime(int year, int month, int day, int hour, int minute)
      : super(year, month, day, hour, minute);
}
