import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../bloc/favorites/favorites_bloc.dart';
import '../../bloc/favorites/favorites_event.dart';
import '../../bloc/favorites/favorites_state.dart';
import '../../screens/event_detail_screen.dart';
import '../../../features/filters/bloc/filter_bloc.dart';
import '../../../features/filters/widgets/filter_bottom_sheet.dart';
import '../../../features/filters/widgets/active_filters_chips.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Event> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    context.read<FavoritesBloc>().add(const LoadFavorites());
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = di.sl<EventRepository>();
      final events = await repository.getAll();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          BlocBuilder<FilterBloc, FilterState>(
            builder: (context, filterState) {
              if (filterState is FilterApplied && filterState.hasActiveFilters) {
                return ActiveFiltersChips(
                  filters: filterState.filters,
                  onRemoveFilter: (type) {
                    context.read<FilterBloc>().add(RemoveFilter(type));
                  },
                  onClearAll: () {
                    context.read<FilterBloc>().add(ClearFilters());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadEvents,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _events.isEmpty
                        ? const Center(
                            child: Text('No events'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEvents,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                final event = _events[index];
                                return BlocBuilder<FavoritesBloc,
                                    FavoritesState>(
                                  builder: (context, favState) {
                                    final isFavorite =
                                        favState is FavoritesLoaded &&
                                            favState.isFavorite(
                                                event.id.toString());
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          event.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_formatTime(event.start)} - ${event.room}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (event.track.isNotEmpty)
                                              Text(
                                                event.track,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isFavorite
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isFavorite
                                                    ? Colors.red
                                                    : null,
                                              ),
                                              onPressed: () {
                                                context
                                                    .read<FavoritesBloc>()
                                                    .add(ToggleFavorite(
                                                        event.id.toString()));
                                              },
                                              tooltip: isFavorite
                                                  ? 'Remove from favorites'
                                                  : 'Add to favorites',
                                            ),
                                            const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EventDetailScreen(
                                                event: event,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
