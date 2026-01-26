import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:fosdem_flutter/presentation/blocs/filter/filter_bloc.dart';
import 'package:fosdem_flutter/data/services/filter_persistence_service.dart';
import 'package:fosdem_flutter/domain/models/filter_models.dart';
import 'package:fosdem_flutter/data/datasources/local/database.dart';
import 'package:drift/native.dart';

void main() {
  group('FilterBloc', () {
    late FilterBloc filterBloc;
    late FilterPersistenceService persistenceService;
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase.test(NativeDatabase.memory());
      persistenceService = FilterPersistenceService(database);
      filterBloc = FilterBloc(persistenceService);
    });

    tearDown(() async {
      filterBloc.close();
      await database.close();
    });

    test('initial state is FilterInitial', () {
      expect(filterBloc.state, isA<FilterInitial>());
    });

    group('UpdateTextSearch', () {
      blocTest<FilterBloc, FilterState>(
        'updates search query',
        build: () => FilterBloc(persistenceService),
        act: (bloc) => bloc.add(const UpdateTextSearch('flutter')),
        expect: () => [
          isA<FilterLoaded>().having(
            (state) => state.currentFilter.searchQuery,
            'searchQuery',
            'flutter',
          ),
        ],
      );
    });

    group('ToggleFilterChip', () {
      blocTest<FilterBloc, FilterState>(
        'toggles track filter',
        build: () => FilterBloc(persistenceService),
        act: (bloc) => bloc.add(const ToggleFilterChip(
          FilterChipType.track,
          'Containers',
        )),
        expect: () => [
          isA<FilterLoaded>().having(
            (state) => state.currentFilter.tracks,
            'tracks',
            {'Containers'},
          ),
        ],
      );
    });

    group('ToggleFavoritesOnly', () {
      blocTest<FilterBloc, FilterState>(
        'toggles favorites filter',
        build: () => FilterBloc(persistenceService),
        act: (bloc) => bloc.add(ToggleFavoritesOnly()),
        expect: () => [
          isA<FilterLoaded>().having(
            (state) => state.currentFilter.favoritesOnly,
            'favoritesOnly',
            true,
          ),
        ],
      );
    });

    group('ClearAllFilters', () {
      blocTest<FilterBloc, FilterState>(
        'clears all filters',
        build: () => FilterBloc(persistenceService),
        act: (bloc) {
          bloc.add(const UpdateTextSearch('flutter'));
          bloc.add(ClearAllFilters());
        },
        expect: () => [
          isA<FilterLoaded>(),
          isA<FilterLoaded>().having(
            (state) => state.currentFilter,
            'currentFilter',
            const EventFilter(),
          ),
        ],
      );
    });
  });
}
