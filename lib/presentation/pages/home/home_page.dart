import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/schedule/schedule_bloc.dart';
import '../../../domain/entities/event_domain.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_constants.dart';
import '../../../features/filters/bloc/filter_bloc.dart';
import '../../../features/filters/widgets/filter_bottom_sheet.dart';
import '../../../features/filters/widgets/active_filters_chips.dart';
import '../../../features/filters/widgets/filter_suggestions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load data on initialization
    context.read<ScheduleBloc>().add(LoadSchedule());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOSDEM'),
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
            icon: const Icon(Icons.search),
            onPressed: () => context.go(RouteConstants.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters chips
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
          // Smart suggestions
          const FilterSuggestions(),
          // Events list
          Expanded(
            child: BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ScheduleError) {
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
                            context.read<ScheduleBloc>().add(LoadSchedule());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is ScheduleLoaded) {
                  return BlocBuilder<FilterBloc, FilterState>(
                    builder: (context, filterState) {
                      List<EventDomain> events = state.events;
                      
                      // Apply filters
                      if (filterState is FilterApplied) {
                        // Note: FilterApplied.applyFilters expects List<Event>, not List<EventDomain>
                        // For now, we'll just use the events as-is
                        // TODO: Convert EventDomain to Event or update filter logic
                      }
                      
                      if (events.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.filter_list_off, size: 64),
                              const SizedBox(height: 16),
                              const Text('No events match your filters'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<FilterBloc>().add(ClearFilters());
                                },
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return _buildEventsList(events);
                    },
                  );
                }
                return const Center(child: Text('Welcome to FOSDEM'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<EventDomain> events) {
    // Group events by day
    final now = DateTime.now();
    final upcomingEvents = events.where((e) => e.startTime.isAfter(now)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    final todayEvents = upcomingEvents.where((e) {
      final today = DateTime.now();
      return e.startTime.year == today.year &&
          e.startTime.month == today.month &&
          e.startTime.day == today.day;
    }).toList();

    return ListView(
      children: [
        if (todayEvents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Today',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ...todayEvents.take(5).map((event) => _buildEventCard(event)),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Upcoming Events',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        ...upcomingEvents.take(20).map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(EventDomain event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(
          '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.room}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.go('${RouteConstants.eventDetail}/${event.id}');
        },
      ),
    );
  }
}
