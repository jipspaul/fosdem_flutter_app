import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/favorites/favorites_bloc.dart';
import '../bloc/favorites/favorites_event.dart';
import '../bloc/favorites/favorites_state.dart';
import '../pages/debug/favorites_debug_page.dart';
import '../../domain/entities/event.dart';
import 'event_detail_screen.dart';
import '../../features/discovery/presentation/screens/event_discovery_screen.dart';
import '../../features/discovery/presentation/bloc/event_discovery_bloc.dart';
import '../../features/discovery/presentation/bloc/event_discovery_event.dart';
import '../../features/discovery/presentation/bloc/event_discovery_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Load favorites when screen is shown
    context.read<FavoritesBloc>().add(const LoadFavorites());
    // Load discovery stats if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discoveryBloc = context.read<EventDiscoveryBloc>();
      final state = discoveryBloc.state;
      if (state is! EventDiscoveryLoaded && state is! EventDiscoveryLoading) {
        discoveryBloc.add(LoadNextEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: 'Discover Events',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventDiscoveryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesDebugPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<FavoritesBloc>().add(const LoadFavorites());
            },
          ),
        ],
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
              if (state is FavoritesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is FavoritesError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<FavoritesBloc>().add(const LoadFavorites());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is FavoritesLoaded) {
            var favorites = state.favorites;
            
            if (favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favorites yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mark events as favorite to see them here',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EventDiscoveryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Discover Events'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FavoritesBloc>().add(const LoadFavorites());
              },
              child: Column(
                children: [
                  // Swipe Progress Section
                  BlocBuilder<EventDiscoveryBloc, EventDiscoveryState>(
                    builder: (context, discoveryState) {
                      int totalSeen = 0;
                      int remaining = 0;
                      double progress = 0.0;
                      
                      if (discoveryState is EventDiscoveryLoaded) {
                        totalSeen = discoveryState.totalSeen;
                        remaining = discoveryState.remainingCount;
                        final total = totalSeen + remaining + 1;
                        progress = total > 0 ? totalSeen / total : 0.0;
                      } else if (discoveryState is EventDiscoveryLoading) {
                        // Show loading state
                        return const Card(
                          margin: EdgeInsets.all(16),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      } else if (discoveryState is EventDiscoveryEmpty) {
                        // All events seen
                        totalSeen = 0; // Will be calculated from database if needed
                        remaining = 0;
                        progress = 1.0;
                      }

                      return Card(
                        margin: const EdgeInsets.all(16),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Event Discovery Progress',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const EventDiscoveryScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.explore, size: 18),
                                    label: const Text('Swipe'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '✅ Seen: $totalSeen',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '⏳ Remaining: $remaining',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              if (remaining == 0 && totalSeen > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.celebration, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'All events reviewed!',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Favorites List
                  Expanded(
                    child: ListView.builder(
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final event = favorites[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(event.title),
                            subtitle: Text(
                              '${event.room} • ${_formatTime(event.startTime)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () {
                                context.read<FavoritesBloc>().add(
                                      RemoveFavorite(event.id.toString()),
                                    );
                              },
                            ),
                            onTap: () {
                              // Navigate to event detail
                              final eventForDetail = Event(
                                id: event.id,
                                title: event.title,
                                subtitle: event.subtitle,
                                abstract: event.abstract,
                                description: event.description,
                                room: event.room,
                                track: event.track ?? '',
                                date: event.startTime,
                                start: event.startTime,
                                duration: event.duration,
                                url: event.url,
                                people: const [],
                                links: const [],
                                attachments: const [],
                                isSync: false,
                              );
                              
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EventDetailScreen(event: eventForDetail),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Pull down to load favorites'),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
