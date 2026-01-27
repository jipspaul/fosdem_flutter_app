import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/journey_models.dart';
import '../bloc/journey_bloc.dart';
import '../bloc/journey_event.dart';
import '../bloc/journey_state.dart';
import '../widgets/journey_timeline_widget.dart';
import '../widgets/conflict_card_widget.dart';
import '../widgets/journey_stats_widget.dart';
import '../widgets/wishlist_widget.dart';

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
            Tab(icon: Icon(Icons.bookmark_border), text: 'Wishlist'),
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
                _buildWishlistTab(state),
              ],
            );
          }

          return const Center(child: Text('Welcome to My Journey'));
        },
      ),
    );
  }

  Widget _buildJourneyTab(JourneyLoaded state) {
          if (state.planned.isEmpty && state.wishlist.isEmpty && state.candidates.isEmpty) {
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

    if (state.planned.isEmpty && state.wishlist.isEmpty && state.candidates.isNotEmpty) {
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
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Favorites (${state.candidates.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),

            // Group candidates by day
            ...state.candidates.groupedByDay().entries.map((entry) {
              return SliverToBoxAdapter(
                child: JourneyTimelineWidget(
                  date: entry.key,
                  events: const [], // No planned events
                  candidates: entry.value, // All are candidates
                  conflicts: const [],
                ),
              );
            }),
          ],
        ),
      );
    }

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
              ),
            );
          }),
        ],
      ),
    );
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
        if (allDays.containsKey(entry.key)) {
          // Day already exists, don't overwrite planned events
        } else {
          // Add new day with empty planned events (candidates will be shown)
          allDays[entry.key] = [];
        }
      }
    }
    
    // Sort by date
    final sortedEntries = allDays.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return Map.fromEntries(sortedEntries);
  }

  Widget _buildWishlistTab(JourneyLoaded state) {
    if (state.wishlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add interesting events from the schedule',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<JourneyBloc>().add(const LoadJourney());
      },
      child: WishlistWidget(items: state.wishlist),
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
