import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home/home_page.dart';
import '../pages/events/events_page.dart';
import '../pages/event_detail/event_detail_page.dart';
import '../pages/search/search_page.dart';
import '../pages/favorites/favorites_page.dart';
import '../pages/tracks/tracks_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/app_shell.dart';
import 'route_constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteConstants.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.events,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EventsPage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.search,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.favorites,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavoritesPage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: RouteConstants.eventDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EventDetailPage(eventId: id);
        },
      ),
      GoRoute(
        path: RouteConstants.tracks,
        builder: (context, state) => const TracksPage(),
      ),
    ],
  );
}
