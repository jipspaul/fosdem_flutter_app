import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/filters/bloc/filter_bloc.dart';
import '../../../features/filters/widgets/filter_bottom_sheet.dart';
import '../../../features/filters/widgets/active_filters_chips.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

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
          // Events content
          const Expanded(
            child: Center(
              child: Text('Events list will be displayed here'),
            ),
          ),
        ],
      ),
    );
  }
}
