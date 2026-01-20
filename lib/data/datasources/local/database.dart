import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;
import 'tables/events_table.dart';
import 'tables/tracks_table.dart';
import 'tables/people_table.dart';
import 'tables/buildings_table.dart';
import 'tables/favorites_table.dart';
import 'tables/cache_metadata_table.dart';
import 'tables/filter_presets_table.dart';
import 'tables/scraped_events_table.dart';
import 'tables/swipe_history_table.dart';
import '../../../features/journey/data/tables/journey_items_table.dart';
import '../../../features/journey/data/daos/journey_items_dao.dart';
import 'daos/events_dao.dart';
import 'daos/tracks_dao.dart';
import 'daos/people_dao.dart';
import 'daos/buildings_dao.dart';
import 'daos/favorites_dao.dart';
import 'daos/cache_dao.dart';
import 'daos/filter_presets_dao.dart';
import 'daos/scraped_events_dao.dart';
import 'daos/swipe_history_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Events, Tracks, People, Buildings, Favorites, CacheMetadataTable, FilterPresets, ScrapedEvents, JourneyItems, SwipeHistory],
  daos: [EventsDao, TracksDao, PeopleDao, BuildingsDao, FavoritesDao, CacheDao, FilterPresetsDao, ScrapedEventsDao, JourneyItemsDao, SwipeHistoryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  // Constructor for testing
  AppDatabase.test(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          
          // Create indexes
          await customStatement('CREATE INDEX IF NOT EXISTS events_track_date_idx ON events(track, date)');
          await customStatement('CREATE INDEX IF NOT EXISTS events_date_start_idx ON events(date, start)');
          await customStatement('CREATE INDEX IF NOT EXISTS events_room_idx ON events(room)');
          await customStatement('CREATE INDEX IF NOT EXISTS tracks_date_idx ON tracks(date)');
          await customStatement('CREATE INDEX IF NOT EXISTS people_name_idx ON people(name)');
          await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS favorites_user_event_idx ON favorites(user_id, event_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS cache_category_idx ON cache_metadata(category)');
          await customStatement('CREATE INDEX IF NOT EXISTS cache_expires_idx ON cache_metadata(expires_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS scraped_events_expires_idx ON scraped_events(expires_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS journey_items_event_idx ON journey_items(event_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS journey_items_status_idx ON journey_items(status)');
          await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS swipe_history_user_event_idx ON swipe_history(user_id, event_id)');
          
          // Note: FTS is not supported on web/IndexedDB
          // Full-text search will be done via LIKE queries instead
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle future migrations
          if (from < 2) {
            await m.addColumn(events, events.url);
          }
          if (from < 3) {
            await m.createTable(cacheMetadataTable);
            await customStatement('CREATE INDEX IF NOT EXISTS cache_category_idx ON cache_metadata(category)');
            await customStatement('CREATE INDEX IF NOT EXISTS cache_expires_idx ON cache_metadata(expires_at)');
          }
          if (from < 4) {
            await m.createTable(filterPresets);
          }
          if (from < 5) {
            await m.createTable(scrapedEvents);
            await customStatement('CREATE INDEX IF NOT EXISTS scraped_events_expires_idx ON scraped_events(expires_at)');
          }
          if (from < 6) {
            await m.createTable(journeyItems);
            await customStatement('CREATE INDEX IF NOT EXISTS journey_items_event_idx ON journey_items(event_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS journey_items_status_idx ON journey_items(status)');
          }
          if (from < 7) {
            await m.createTable(swipeHistory);
            await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS swipe_history_user_event_idx ON swipe_history(user_id, event_id)');
          }
        },
        beforeOpen: (details) async {
          // Note: Some PRAGMA statements don't work on web/IndexedDB
          // Enable foreign keys (if supported)
          try {
            await customStatement('PRAGMA foreign_keys = ON');
          } catch (e) {
            // Ignore on web
          }
        },
      );

  // Search events using LIKE queries (web-compatible alternative to FTS)
  Future<List<EventEntity>> searchEvents(String query) async {
    if (query.isEmpty) return [];
    
    final searchPattern = '%${query.toLowerCase()}%';
    
    return await (select(events)
          ..where((e) =>
              e.title.lower().like(searchPattern) |
              e.subtitle.lower().like(searchPattern) |
              e.abstract.lower().like(searchPattern) |
              e.track.lower().like(searchPattern) |
              e.room.lower().like(searchPattern))
          ..limit(50))
        .get();
  }

  // Get database size (web doesn't support this easily, return 0)
  Future<int> getDatabaseSize() async {
    // Web storage doesn't expose size easily
    return 0;
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(events).go();
      await delete(tracks).go();
      await delete(people).go();
      await delete(buildings).go();
      await delete(favorites).go();
    });
  }

  // Export database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final eventsCount = await (select(events)).get().then((e) => e.length);
    final tracksCount = await (select(tracks)).get().then((t) => t.length);
    final peopleCount = await (select(people)).get().then((p) => p.length);
    final buildingsCount = await (select(buildings)).get().then((b) => b.length);
    final favoritesCount = await (select(favorites)).get().then((f) => f.length);
    
    return {
      'events': eventsCount,
      'tracks': tracksCount,
      'people': peopleCount,
      'buildings': buildingsCount,
      'favorites': favoritesCount,
    };
  }
}
