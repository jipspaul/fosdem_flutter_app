import 'package:flutter/material.dart';
import '../models/event_filter.dart';

class ActiveFiltersChips extends StatelessWidget {
  final List<EventFilter> filters;
  final Function(FilterType) onRemoveFilter;
  final VoidCallback onClearAll;

  const ActiveFiltersChips({
    super.key,
    required this.filters,
    required this.onRemoveFilter,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...filters.map((filter) => Chip(
            label: Text(filter.criterion.getLabel()),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () => onRemoveFilter(filter.type),
          )),
          if (filters.length > 1)
            ActionChip(
              label: const Text('Clear All'),
              onPressed: onClearAll,
            ),
        ],
      ),
    );
  }
}
