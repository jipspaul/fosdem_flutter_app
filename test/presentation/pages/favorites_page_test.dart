import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fosdem_flutter/presentation/pages/favorites/favorites_page.dart';
import 'package:fosdem_flutter/presentation/bloc/favorites/favorites_bloc.dart';
import 'package:fosdem_flutter/presentation/bloc/favorites/favorites_state.dart';
import 'package:fosdem_flutter/presentation/bloc/favorites/favorites_event.dart';
import 'package:fosdem_flutter/domain/entities/event_domain.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FavoritesBloc])
import 'favorites_page_test.mocks.dart';

void main() {
  late MockFavoritesBloc mockBloc;

  setUp(() {
    mockBloc = MockFavoritesBloc();
  });

  tearDown(() {
    mockBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<FavoritesBloc>.value(
        value: mockBloc,
        child: const FavoritesPage(),
      ),
    );
  }

  group('FavoritesPage Widget Tests', () {
    testWidgets('displays loading indicator when loading', (tester) async {
      when(mockBloc.state).thenReturn(const FavoritesLoading());
      when(mockBloc.stream).thenAnswer((_) => Stream.value(const FavoritesLoading()));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
    });

    testWidgets('displays empty state when no favorites', (tester) async {
      when(mockBloc.state).thenReturn(const FavoritesLoaded(favorites: [], favoriteIds: {}));
      when(mockBloc.stream).thenAnswer(
        (_) => Stream.value(const FavoritesLoaded(favorites: [], favoriteIds: {})),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('No favorites yet'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('displays favorite events', (tester) async {
      final testEvents = [
        EventDomain(
          id: 1,
          title: 'Test Event 1',
          subtitle: 'Subtitle 1',
          track: 'Track A',
          type: 'talk',
          startTime: DateTime(2024, 2, 3, 10, 0),
          endTime: DateTime(2024, 2, 3, 11, 0),
          duration: 60,
          room: 'Room 1',
          day: 1,
          isFavorite: true,
          isNotified: false,
        ),
      ];

      when(mockBloc.state).thenReturn(
        FavoritesLoaded(
          favorites: testEvents,
          favoriteIds: {'1'},
        ),
      );
      when(mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          FavoritesLoaded(
            favorites: testEvents,
            favoriteIds: {'1'},
          ),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Test Event 1'), findsOneWidget);
      expect(find.text('Subtitle 1'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
