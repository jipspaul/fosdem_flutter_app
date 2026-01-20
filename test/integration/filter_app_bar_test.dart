import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fosdem_flutter/features/filters/bloc/filter_bloc.dart';
import 'package:fosdem_flutter/features/filters/services/filter_persistence_service.dart';
import 'package:fosdem_flutter/features/filters/models/event_filter.dart';
import 'package:fosdem_flutter/features/filters/models/filter_criterion.dart';
import 'package:fosdem_flutter/presentation/pages/favorites/favorites_page.dart';
import 'package:fosdem_flutter/presentation/pages/events/events_page.dart';
import 'package:fosdem_flutter/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:get_it/get_it.dart';

void main() {
  group('Filter App Bar Integration Tests', () {
    late FilterBloc filterBloc;
    late FilterPersistenceService persistenceService;
    late SharedPreferences prefs;

    setUp(() async {
      prefs = await SharedPreferences.getInstance();
      persistenceService = FilterPersistenceService(prefs);
      filterBloc = FilterBloc(persistenceService: persistenceService);
    });

    tearDown(() {
      filterBloc.close();
    });

    testWidgets('Favorites page should have filter button in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<FilterBloc>.value(value: filterBloc),
            ],
            child: const FavoritesPage(),
          ),
        ),
      );

      // Verify filter button exists in app bar
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('Events page should have filter button in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const EventsPage(),
          ),
        ),
      );

      // Verify filter button exists in app bar
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('Tapping filter button should open filter bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const EventsPage(),
          ),
        ),
      );

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears
      expect(find.text('Filters'), findsOneWidget);
    });

    testWidgets('Active filters should display chips below app bar',
        (WidgetTester tester) async {
      // Apply a filter - using the actual EventFilter structure
      filterBloc.add(AddFilter(EventFilter(
        type: FilterType.track,
        criterion: TrackCriterion(tracks: ['Security']),
      )));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const EventsPage(),
          ),
        ),
      );

      await tester.pump();

      // Verify filter chip is displayed
      expect(find.text('Track: Security'), findsOneWidget);
    });

    testWidgets('Removing filter chip should clear the filter',
        (WidgetTester tester) async {
      // Apply a filter - using the actual EventFilter structure
      filterBloc.add(AddFilter(EventFilter(
        type: FilterType.track,
        criterion: TrackCriterion(tracks: ['Security']),
      )));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const EventsPage(),
          ),
        ),
      );

      await tester.pump();

      // Find and tap close button on chip
      final closeButton = find.descendant(
        of: find.widgetWithText(Chip, 'Track: Security'),
        matching: find.byIcon(Icons.close),
      );

      await tester.tap(closeButton);
      await tester.pump();

      // Verify filter is removed
      expect(filterBloc.state, isA<FilterInitial>());
    });
  });
}
