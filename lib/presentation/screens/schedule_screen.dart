import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/event.dart';
import '../bloc/schedule/schedule_bloc.dart';
import '../bloc/favorites/favorites_bloc.dart';
import '../bloc/favorites/favorites_event.dart';
import '../bloc/favorites/favorites_state.dart';
import '../../../features/filters/bloc/filter_bloc.dart';
import '../../../features/filters/widgets/filter_bottom_sheet.dart';
import '../../../features/filters/widgets/active_filters_chips.dart';
import '../../../features/filters/widgets/filter_manager.dart';
import '../../../features/filters/models/filter_criterion.dart';
import '../../../features/filters/models/event_filter.dart';
import 'event_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _currentPage = 0;
  List<Event> _allEvents = [];
  List<Event> _originalEvents = []; // Keep original unfiltered events
  List<Event> _displayedEvents = [];
  bool _isLoadingMore = false;
  FilterState? _lastFilterState; // Track last filter state to prevent rebuilds

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<ScheduleBloc>().add(const LoadSchedule());
    context.read<FavoritesBloc>().add(const LoadFavorites());
    context.read<FilterBloc>().add(LoadSavedFilters());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreEvents();
    }
  }

  void _loadMoreEvents() {
    if (_displayedEvents.length >= _allEvents.length) return;
    
    setState(() {
      _isLoadingMore = true;
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _allEvents.length);
      _displayedEvents.addAll(_allEvents.sublist(startIndex, endIndex));
      _currentPage++;
      _isLoadingMore = false;
    });
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
            onPressed: () {
              setState(() {
                _currentPage = 0;
                _displayedEvents.clear();
              });
              context.read<ScheduleBloc>().add(const LoadSchedule());
            },
          ),
        ],
      ),
      body: BlocBuilder<FilterBloc, FilterState>(
        buildWhen: (previous, current) {
          print('DEBUG: FilterBloc buildWhen - previous: ${previous.runtimeType}, current: ${current.runtimeType}');
          // Only rebuild if filter state actually changed
          if (previous is FilterApplied && current is FilterApplied) {
            final filtersChanged = previous.filters.length != current.filters.length ||
                !_filterListsEqual(previous.filters, current.filters);
            print('DEBUG: Filters changed: $filtersChanged');
            return filtersChanged;
          }
          return true;
        },
        builder: (context, filterState) {
          print('DEBUG: Building schedule screen with filterState: ${filterState.runtimeType}');
          return BlocConsumer<ScheduleBloc, ScheduleState>(
            listener: (context, state) {
              if (state is ScheduleLoaded) {
                setState(() {
                  // Convert EventDomain to Event
                  _originalEvents = state.events.map((e) => Event(
                    id: e.id,
                    title: e.title,
                    subtitle: e.subtitle,
                    abstract: e.abstract,
                    description: e.description,
                    start: e.startTime,
                    date: e.startTime,
                    duration: e.duration,
                    room: e.room,
                    track: e.track ?? '',
                    url: e.url,
                    people: const [],
                    links: const [],
                    attachments: const [],
                    isSync: false,
                  )).toList();
                  
                  _applyFilters();
                });
              }
            },
            buildWhen: (previous, current) => current is ScheduleLoaded || 
                                                current is ScheduleLoading || 
                                                current is ScheduleError,
            builder: (context, state) {
              // Apply filters when filter state changes (only if state actually changed)
              if (filterState is FilterApplied && filterState != _lastFilterState) {
                print('DEBUG: Filter state changed, applying filters');
                _lastFilterState = filterState;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _applyFilters();
                });
              } else if (filterState is! FilterApplied && _lastFilterState != null) {
                // Filter was cleared
                print('DEBUG: Filters cleared');
                _lastFilterState = null;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _applyFilters();
                });
              }

              if (state is ScheduleLoading && _displayedEvents.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ScheduleError && _displayedEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ScheduleBloc>().add(const LoadSchedule());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (_displayedEvents.isEmpty) {
                if (filterState is FilterApplied && filterState.hasActiveFilters) {
                  // No events match filters
                  return Column(
                    children: [
                      const FilterManager(),
                      if (filterState is FilterApplied && filterState.hasActiveFilters)
                        ActiveFiltersChips(
                          filters: filterState.filters,
                          onRemoveFilter: (type) {
                            context.read<FilterBloc>().add(RemoveFilter(type));
                          },
                          onClearAll: () {
                            context.read<FilterBloc>().add(ClearFilters());
                          },
                        ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No events match the current filters',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting or removing filters',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: Text('No events available'));
                }
              }

              return Column(
                children: [
                  // Filter Manager
                  const FilterManager(),
                  // Active filters chips (for quick removal)
                  if (filterState is FilterApplied && filterState.hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text('DEBUG: ${filterState.filters.length} active filters', 
                            style: const TextStyle(fontSize: 10, color: Colors.red)),
                          ActiveFiltersChips(
                            filters: filterState.filters,
                            onRemoveFilter: (type) {
                              print('DEBUG: Removing filter type: $type');
                              context.read<FilterBloc>().add(RemoveFilter(type));
                            },
                            onClearAll: () {
                              print('DEBUG: Clearing all filters');
                              context.read<FilterBloc>().add(ClearFilters());
                            },
                          ),
                        ],
                      ),
                    ),
                  // Events list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _currentPage = 0;
                          _displayedEvents.clear();
                        });
                        context.read<ScheduleBloc>().add(const RefreshSchedule());
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _displayedEvents.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _displayedEvents.length) {
                            return _displayedEvents.length < _allEvents.length
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : const SizedBox.shrink();
                          }

                          final event = _displayedEvents[index];
                          return BlocBuilder<FavoritesBloc, FavoritesState>(
                            builder: (context, favState) {
                              final isFavorite = favState is FavoritesLoaded && 
                                                favState.isFavorite(event.id.toString());
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  title: Text(event.title),
                                  subtitle: Text('${event.start.toLocal()} - ${event.room}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: isFavorite ? Colors.red : null,
                                        ),
                                        onPressed: () {
                                          context.read<FavoritesBloc>().add(
                                            ToggleFavorite(event.id.toString()),
                                          );
                                        },
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => EventDetailScreen(event: event),
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
              );
            },
          );
        },
      ),
    );
  }

  void _applyFilters() {
    final filterState = context.read<FilterBloc>().state;
    
    print('DEBUG: _applyFilters called');
    print('DEBUG: filterState type: ${filterState.runtimeType}');
    
    // Start with original unfiltered events
    List<Event> filteredEvents = List.from(_originalEvents);
    print('DEBUG: Starting with ${filteredEvents.length} original events');
    
    if (filterState is FilterApplied && filterState.hasActiveFilters) {
      print('DEBUG: FilterApplied with ${filterState.filters.length} active filters');
      
      // Apply standard filters
      filteredEvents = filterState.applyFilters(filteredEvents).cast<Event>();
      print('DEBUG: After standard filters: ${filteredEvents.length} events');
      
      // Handle favorites filter separately - only if explicitly added by user
      final hasFavoritesFilter = filterState.filters.any(
        (f) => f.type == FilterType.favorites && f.enabled,
      );
      
      if (hasFavoritesFilter) {
        print('DEBUG: Applying favorites filter');
        final favoritesState = context.read<FavoritesBloc>().state;
        if (favoritesState is FavoritesLoaded) {
          filteredEvents = filteredEvents.where((event) {
            return favoritesState.isFavorite(event.id.toString());
          }).toList();
          print('DEBUG: After favorites filter: ${filteredEvents.length} events');
        }
      } else {
        print('DEBUG: No favorites filter active, skipping');
      }
      
      // Handle duration filter - only if explicitly added by user
      final hasDurationFilter = filterState.filters.any(
        (f) => f.type == FilterType.duration && f.enabled,
      );
      
      if (hasDurationFilter) {
        print('DEBUG: Applying duration filter');
        final durationFilter = filterState.filters.firstWhere(
          (f) => f.type == FilterType.duration && f.enabled,
        );
        final criterion = durationFilter.criterion as DurationCriterion;
        filteredEvents = filteredEvents.where((event) {
          final eventDuration = Duration(minutes: event.duration);
          return eventDuration >= criterion.minDuration && 
                 eventDuration <= criterion.maxDuration;
        }).toList();
        print('DEBUG: After duration filter: ${filteredEvents.length} events');
      } else {
        print('DEBUG: No duration filter active, skipping');
      }
    } else {
      print('DEBUG: No filters applied, showing all events');
    }
    
    print('DEBUG: Final event count: ${filteredEvents.length}');
    
    setState(() {
      // Update _allEvents with filtered results, but keep _originalEvents unchanged
      _allEvents = filteredEvents;
      _currentPage = 0;
      _displayedEvents.clear();
      _loadMoreEvents();
    });
  }

  // Helper method to compare filter lists
  bool _filterListsEqual(List<EventFilter> list1, List<EventFilter> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].type != list2[i].type || list1[i].enabled != list2[i].enabled) {
        return false;
      }
    }
    return true;
  }
}
