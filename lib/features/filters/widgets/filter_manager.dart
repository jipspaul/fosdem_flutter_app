import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/filter_bloc.dart';
import '../models/event_filter.dart';
import 'filter_bottom_sheet.dart';

class FilterManager extends StatelessWidget {
  const FilterManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, state) {
        if (state is! FilterApplied) {
          return const SizedBox.shrink();
        }

        final filters = state.filters;
        final hasActiveFilters = state.hasActiveFilters;

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    if (hasActiveFilters)
                      TextButton(
                        onPressed: () {
                          context.read<FilterBloc>().add(ClearFilters());
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'Add Filter',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => const FilterBottomSheet(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Active filters list
              if (hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filters.map((filter) {
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getFilterIcon(filter.type),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                filter.criterion.getLabel(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: filter.enabled
                                      ? null
                                      : TextDecoration.lineThrough,
                                  color: filter.enabled
                                      ? null
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selected: filter.enabled,
                        onSelected: (selected) {
                          context.read<FilterBloc>().add(
                                AddFilter(
                                  filter.copyWith(enabled: selected),
                                ),
                              );
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          context.read<FilterBloc>().add(
                                RemoveFilter(filter.type),
                              );
                        },
                        avatar: Icon(
                          filter.enabled ? Icons.check_circle : Icons.circle_outlined,
                          size: 16,
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    'No active filters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFilterIcon(FilterType type) {
    switch (type) {
      case FilterType.text:
        return Icons.search;
      case FilterType.track:
        return Icons.label;
      case FilterType.room:
        return Icons.room;
      case FilterType.dateRange:
        return Icons.calendar_today;
      case FilterType.timeRange:
        return Icons.access_time;
      case FilterType.duration:
        return Icons.timer;
      case FilterType.favorites:
        return Icons.favorite;
    }
  }
}
