import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/filter_models.dart';
import '../../../presentation/blocs/filter/filter_bloc.dart';
import 'package:fosdem_flutter/presentation/widgets/filters/filter_chip_group.dart';
import 'package:fosdem_flutter/presentation/widgets/filters/date_time_filter.dart';
import 'package:fosdem_flutter/presentation/widgets/filters/search_filter.dart';
import 'package:fosdem_flutter/presentation/widgets/filters/duration_filter.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, state) {
        if (state is! FilterLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final filter = state.currentFilter;

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear All'),
                              onPressed: () {
                                context.read<FilterBloc>().add(ClearAllFilters());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Filter content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        // Search filter
                        SearchFilter(
                          label: 'Search',
                          value: filter.searchQuery,
                          hint: 'Search events, speakers, descriptions...',
                          icon: Icons.search,
                          onChanged: (value) {
                            context.read<FilterBloc>().add(
                                  UpdateTextSearch(value.isEmpty ? '' : value),
                                );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Date range filter
                        DateTimeFilter(
                          label: 'Date Range',
                          startDate: filter.dateRange?.start,
                          endDate: filter.dateRange?.end,
                          icon: Icons.calendar_month,
                          onStartDateChanged: (date) {
                            if (date != null) {
                              final endDate = filter.dateRange?.end ?? date.add(const Duration(days: 1));
                              context.read<FilterBloc>().add(
                                    UpdateDateRange(DateTimeRange(start: date, end: endDate)),
                                  );
                            }
                          },
                          onEndDateChanged: (date) {
                            if (date != null) {
                              final startDate = filter.dateRange?.start ?? date.subtract(const Duration(days: 1));
                              context.read<FilterBloc>().add(
                                    UpdateDateRange(DateTimeRange(start: startDate, end: date)),
                                  );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        // Duration filter
                        DurationFilter(
                          label: 'Duration',
                          minDuration: filter.durationRange?.start.toInt() ?? 0,
                          maxDuration: filter.durationRange?.end.toInt() ?? 180,
                          icon: Icons.schedule,
                          onMinDurationChanged: (value) {
                            final max = filter.durationRange?.end ?? 180.0;
                            context.read<FilterBloc>().add(
                                  UpdateDurationRange(RangeValues((value ?? 0).toDouble(), max)),
                                );
                          },
                          onMaxDurationChanged: (value) {
                            final min = filter.durationRange?.start ?? 0.0;
                            context.read<FilterBloc>().add(
                                  UpdateDurationRange(RangeValues(min, (value ?? 180).toDouble())),
                                );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Track filter - TODO: Load available tracks from repository
                        FilterChipGroup(
                          label: 'Tracks',
                          options: const [], // TODO: Load from repository
                          selectedOptions: filter.tracks.toList(),
                          icon: Icons.category,
                          onChanged: (selected) {
                            context.read<FilterBloc>().add(
                                  ApplyFilter(filter.copyWith(tracks: selected.toSet())),
                                );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Room filter - TODO: Load available rooms from repository
                        FilterChipGroup(
                          label: 'Rooms',
                          options: const [], // TODO: Load from repository
                          selectedOptions: filter.rooms.toList(),
                          icon: Icons.meeting_room,
                          onChanged: (selected) {
                            context.read<FilterBloc>().add(
                                  ApplyFilter(filter.copyWith(rooms: selected.toSet())),
                                );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Event type filter - TODO: Load available types from repository
                        FilterChipGroup(
                          label: 'Event Types',
                          options: const [], // TODO: Load from repository
                          selectedOptions: filter.eventTypes.toList(),
                          icon: Icons.event,
                          onChanged: (selected) {
                            context.read<FilterBloc>().add(
                                  ApplyFilter(filter.copyWith(eventTypes: selected.toSet())),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Bottom action bar
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${filter.activeFilterCount} active filters',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Apply Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
