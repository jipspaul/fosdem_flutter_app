import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/journey_models.dart';
import '../../domain/models/journey_export_model.dart';
import '../bloc/journey_bloc.dart';
import '../bloc/journey_event.dart';
import '../bloc/journey_state.dart';
import '../widgets/journey_timeline_widget.dart';
import '../widgets/conflict_card_widget.dart';
import '../widgets/journey_stats_widget.dart';
import '../../../../presentation/bloc/favorites/favorites_bloc.dart';
import '../../../../presentation/bloc/favorites/favorites_event.dart';
import '../../../../presentation/bloc/favorites/favorites_state.dart';
import '../../../../domain/entities/event.dart';
import '../../../../presentation/screens/event_detail_screen.dart';
import 'package:intl/intl.dart';

class MyJourneyScreen extends StatefulWidget {
  const MyJourneyScreen({super.key});

  @override
  State<MyJourneyScreen> createState() => _MyJourneyScreenState();
}

class _MyJourneyScreenState extends State<MyJourneyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFavorites = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<JourneyBloc>().add(const LoadJourney());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journey'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Journey'),
            Tab(icon: Icon(Icons.people), text: "Friends' timelines"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<JourneyBloc>().add(const LoadJourney());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Open settings
            },
          ),
        ],
      ),
      body: BlocBuilder<JourneyBloc, JourneyState>(
        builder: (context, state) {
          if (state is JourneyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is JourneyError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<JourneyBloc>().add(const LoadJourney());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is JourneyLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildJourneyTab(state),
                _buildFriendsTab(state),
              ],
            );
          }

          return const Center(child: Text('Welcome to My Journey'));
        },
      ),
    );
  }

  Widget _buildJourneyTab(JourneyLoaded state) {
    print('[Journey] _buildJourneyTab: planned=${state.planned.length} wishlist=${state.wishlist.length} candidates=${state.candidates.length} imported=${state.importedJourneys.length} showImported=${state.showImportedJourney}');
    // Empty journey and no imported journeys: show empty state
    if (state.planned.isEmpty && state.wishlist.isEmpty && state.candidates.isEmpty && state.importedJourneys.isEmpty) {
      print('[Journey] _buildJourneyTab: branch=empty');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Your journey is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add events from the schedule as favorites first',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Only imported journeys (no own events): show imported timeline and toggle
    if (state.planned.isEmpty && state.wishlist.isEmpty && state.candidates.isEmpty && state.importedJourneys.isNotEmpty) {
      print('[Journey] _buildJourneyTab: branch=imported-only');
      final days = _getDaysToShow(state);
      print('[Journey] _buildJourneyTab: days count=${days.length} dates=${days.keys.map((d) => d.toIso8601String().substring(0, 10)).toList()}');
      return RefreshIndicator(
        onRefresh: () async {
          context.read<JourneyBloc>().add(const LoadJourney());
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Imported journey${state.importedJourneys.length > 1 ? 's' : ''} from Settings. Toggle below to show or hide.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: SwitchListTile(
                    title: const Text('Show imported journey'),
                    value: state.showImportedJourney,
                    onChanged: (value) {
                      context.read<JourneyBloc>().add(SetShowImportedJourney(value));
                    },
                    secondary: Icon(
                      state.showImportedJourney ? Icons.people : Icons.people_outline,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            ...days.entries.map((entry) {
              return SliverToBoxAdapter(
                child: JourneyTimelineWidget(
                  date: entry.key,
                  events: const [],
                  candidates: const [],
                  conflicts: const [],
                  importedEntries: state.showImportedJourney ? _buildImportedEntries(state) : [],
                ),
              );
            }),
          ],
        ),
      );
    }

    if (state.planned.isEmpty && state.wishlist.isEmpty && state.candidates.isNotEmpty) {
      print('[Journey] _buildJourneyTab: branch=candidates-only');
      // Show only favorites as candidates
      return RefreshIndicator(
        onRefresh: () async {
          context.read<JourneyBloc>().add(const LoadJourney());
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your favorites are shown below. Tap "Add" to add them to your journey.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Show imported journey toggle when we have imported journeys
            if (state.importedJourneys.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    child: SwitchListTile(
                      title: const Text('Show imported journey'),
                      value: state.showImportedJourney,
                      onChanged: (value) {
                        context.read<JourneyBloc>().add(SetShowImportedJourney(value));
                      },
                      secondary: Icon(
                        state.showImportedJourney ? Icons.people : Icons.people_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Favorites (${state.candidates.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),

            // Group by day: candidates + (when showImported) imported days
            ..._getDaysToShow(state).entries.map((entry) {
              final candidatesOnDay = _showFavorites
                  ? state.candidates.where((c) {
                      return c.startTime.year == entry.key.year &&
                          c.startTime.month == entry.key.month &&
                          c.startTime.day == entry.key.day;
                    }).toList()
                  : <JourneyItem>[];
              return SliverToBoxAdapter(
                child: JourneyTimelineWidget(
                  date: entry.key,
                  events: const [],
                  candidates: candidatesOnDay,
                  conflicts: const [],
                  importedEntries: state.showImportedJourney
                      ? _buildImportedEntries(state)
                      : [],
                ),
              );
            }),
          ],
        ),
      );
    }

    print('[Journey] _buildJourneyTab: branch=main-timeline');
    return RefreshIndicator(
      onRefresh: () async {
        context.read<JourneyBloc>().add(const LoadJourney());
      },
      child: CustomScrollView(
        slivers: [
          // Stats Section
          SliverToBoxAdapter(
            child: JourneyStatsWidget(stats: state.stats),
          ),

          // Toggle for showing favorites
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: SwitchListTile(
                  title: const Text('Show favorite events on timeline'),
                  subtitle: Text(
                    _showFavorites 
                      ? 'Favorites are shown as candidates' 
                      : 'Only planned events are shown',
                  ),
                  value: _showFavorites,
                  onChanged: (value) {
                    setState(() {
                      _showFavorites = value;
                    });
                  },
                  secondary: Icon(
                    _showFavorites ? Icons.bookmark : Icons.bookmark_border,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),

          // Toggle for showing imported journey(s)
          if (state.importedJourneys.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: SwitchListTile(
                    title: const Text('Show imported journey'),
                    subtitle: Text(
                      state.showImportedJourney
                          ? 'Imported events are shown on timeline'
                          : 'Imported events are hidden',
                    ),
                    value: state.showImportedJourney,
                    onChanged: (value) {
                      context.read<JourneyBloc>().add(SetShowImportedJourney(value));
                    },
                    secondary: Icon(
                      state.showImportedJourney ? Icons.people : Icons.people_outline,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),

          // Conflicts Section
          if (state.conflicts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${state.conflicts.length} Conflict${state.conflicts.length > 1 ? 's' : ''} Detected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...state.conflicts.take(3).map((conflict) {
                          return ConflictCardWidget(conflict: conflict);
                        }),
                        if (state.conflicts.length > 3)
                          TextButton(
                            onPressed: () {
                              // TODO: Show all conflicts
                            },
                            child: Text('View all ${state.conflicts.length} conflicts'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Timeline Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

          // Group events by day - include days from both planned and candidates
          ..._getDaysToShow(state).entries.map((entry) {
            return SliverToBoxAdapter(
              child: JourneyTimelineWidget(
                date: entry.key,
                events: entry.value,
                candidates: _showFavorites ? state.candidates : [],
                conflicts: state.conflicts,
                importedEntries: state.showImportedJourney
                    ? _buildImportedEntries(state)
                    : [],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<ImportedEventEntry> _buildImportedEntries(JourneyLoaded state) {
    final list = <ImportedEventEntry>[];
    for (final entry in state.importedJourneys.entries) {
      final key = entry.key;
      final data = entry.value;
      for (final e in data.events) {
        list.add(ImportedEventEntry(
          item: e.toJourneyItem(key),
          userName: data.userName,
          userPictureUrl: data.userPictureUrl,
          status: e.status,
        ));
      }
    }
    print('[Journey] _buildImportedEntries: ${list.length} entries from ${state.importedJourneys.length} users');
    return list;
  }

  Map<DateTime, List<JourneyItem>> _getDaysToShow(JourneyLoaded state) {
    final allDays = <DateTime, List<JourneyItem>>{};
    
    // Add all days from planned events
    final plannedByDay = state.planned.groupedByDay();
    allDays.addAll(plannedByDay);
    
    // If showing favorites, also add days from candidates
    if (_showFavorites) {
      final candidatesByDay = state.candidates.groupedByDay();
      for (final entry in candidatesByDay.entries) {
        if (!allDays.containsKey(entry.key)) {
          allDays[entry.key] = [];
        }
      }
    }
    
    // If showing imported journey, add days from imported events
    if (state.showImportedJourney && state.importedJourneys.isNotEmpty) {
      for (final data in state.importedJourneys.values) {
        for (final e in data.events) {
          final start = e.startTime.isNotEmpty ? DateTime.tryParse(e.startTime) : null;
          if (start != null) {
            final day = DateTime(start.year, start.month, start.day);
            allDays.putIfAbsent(day, () => []);
          }
        }
      }
    }
    
    // Sort by date
    final sortedEntries = allDays.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    print('[Journey] _getDaysToShow: ${sortedEntries.length} days showImported=${state.showImportedJourney} importedCount=${state.importedJourneys.length}');
    return Map.fromEntries(sortedEntries);
  }

  Widget _buildFriendsTab(JourneyLoaded state) {
    if (state.importedJourneys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                "No friends' timelines yet",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Import a friend's journey from Settings (Journey → Import from URL) to see their timeline here and add events to your favorites.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<JourneyBloc>().add(const LoadJourney());
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Friends' timelines",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tap the heart on an event to add it to your favorites.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          ...state.importedJourneys.entries.map((entry) {
            final data = entry.value;
            final eventsByDay = <DateTime, List<JourneyExportEvent>>{};
            for (final e in data.events) {
              final start = e.startTime.isNotEmpty ? DateTime.tryParse(e.startTime) : null;
              if (start != null) {
                final day = DateTime(start.year, start.month, start.day);
                eventsByDay.putIfAbsent(day, () => []).add(e);
              }
            }
            for (final list in eventsByDay.values) {
              list.sort((a, b) {
                final sa = DateTime.tryParse(a.startTime) ?? DateTime.now();
                final sb = DateTime.tryParse(b.startTime) ?? DateTime.now();
                return sa.compareTo(sb);
              });
            }
            final sortedDays = eventsByDay.keys.toList()..sort();

            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Friend header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              backgroundImage: data.userPictureUrl != null &&
                                      data.userPictureUrl!.isNotEmpty
                                  ? NetworkImage(data.userPictureUrl!)
                                  : null,
                              child: data.userPictureUrl == null ||
                                      data.userPictureUrl!.isEmpty
                                  ? Text(
                                      data.userName.isNotEmpty
                                          ? data.userName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data.userName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timeline by day
                      ...sortedDays.map((day) {
                        final dayEvents = eventsByDay[day]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                DateFormat('EEEE, MMM d').format(day),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            ...dayEvents.map((e) => _FriendEventTile(
                                  exportEvent: e,
                                  onAddToFavorites: () {
                                    context.read<FavoritesBloc>().add(
                                          AddFavorite(e.eventId.toString()),
                                        );
                                    },
                                )),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// A single event row in a friend's timeline with "Add to favorites" action.
class _FriendEventTile extends StatelessWidget {
  final JourneyExportEvent exportEvent;
  final VoidCallback onAddToFavorites;

  const _FriendEventTile({
    required this.exportEvent,
    required this.onAddToFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final start = exportEvent.startTime.isNotEmpty
        ? DateTime.tryParse(exportEvent.startTime)
        : null;
    final end = exportEvent.endTime.isNotEmpty
        ? DateTime.tryParse(exportEvent.endTime)
        : null;
    final startStr = start != null
        ? DateFormat.Hm().format(start)
        : '--:--';
    final endStr = end != null ? DateFormat.Hm().format(end) : '--:--';

    final startDt = start ?? DateTime.now();
    final durationMinutes = end != null && start != null
        ? end.difference(start).inMinutes
        : 60;

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(
              event: Event(
                id: exportEvent.eventId,
                title: exportEvent.eventName,
                subtitle: null,
                abstract: null,
                description: null,
                start: startDt,
                date: startDt,
                duration: durationMinutes,
                room: exportEvent.room,
                track: exportEvent.track,
                url: null,
                people: const [],
                links: const [],
                attachments: const [],
                isSync: false,
              ),
            ),
          ),
        );
      },
      leading: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              startStr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              endStr,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        exportEvent.eventName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${exportEvent.room} • ${exportEvent.track}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: BlocBuilder<FavoritesBloc, FavoritesState>(
        buildWhen: (prev, curr) {
          if (curr is! FavoritesLoaded && prev is! FavoritesLoaded) return false;
          final prevIds = prev is FavoritesLoaded ? prev.favoriteIds : <String>{};
          final currIds = curr is FavoritesLoaded ? curr.favoriteIds : <String>{};
          return prevIds.contains(exportEvent.eventId.toString()) !=
              currIds.contains(exportEvent.eventId.toString());
        },
        builder: (context, favState) {
          final isFavorite = favState is FavoritesLoaded &&
              favState.isFavorite(exportEvent.eventId.toString());
          return IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            tooltip: isFavorite ? 'In favorites' : 'Add to favorites',
            onPressed: onAddToFavorites,
          );
        },
      ),
    );
  }
}

extension JourneyItemGrouping on List<JourneyItem> {
  Map<DateTime, List<JourneyItem>> groupedByDay() {
    final grouped = <DateTime, List<JourneyItem>>{};
    
    for (final item in this) {
      final day = DateTime(
        item.startTime.year,
        item.startTime.month,
        item.startTime.day,
      );
      grouped.putIfAbsent(day, () => []).add(item);
    }

    // Sort events within each day
    for (final entries in grouped.values) {
      entries.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}
