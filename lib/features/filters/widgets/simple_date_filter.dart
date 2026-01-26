import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/filter_bloc.dart';
import '../models/event_filter.dart';
import '../models/filter_criterion.dart';

class SimpleDateFilter extends StatelessWidget {
  final Set<String>? selectedBlocks;

  const SimpleDateFilter({
    super.key,
    this.selectedBlocks,
  });

  @override
  Widget build(BuildContext context) {
    return _SimpleDateFilterContent(
      initialSelectedBlocks: selectedBlocks?.toSet() ?? {},
    );
  }
}

class _SimpleDateFilterContent extends StatefulWidget {
  final Set<String> initialSelectedBlocks;

  const _SimpleDateFilterContent({
    required this.initialSelectedBlocks,
  });

  @override
  State<_SimpleDateFilterContent> createState() => _SimpleDateFilterContentState();
}

class _SimpleDateFilterContentState extends State<_SimpleDateFilterContent> {
  late Set<String> _selectedBlocks;

  @override
  void initState() {
    super.initState();
    _selectedBlocks = widget.initialSelectedBlocks.toSet();
  }

  void _toggleBlock(String block) {
    setState(() {
      if (_selectedBlocks.contains(block)) {
        _selectedBlocks.remove(block);
      } else {
        _selectedBlocks.add(block);
      }
    });
  }

  void _applyFilter(BuildContext context) {
    final filterBloc = context.read<FilterBloc>();
    
    if (_selectedBlocks.isEmpty) {
      // Remove filter if nothing selected
      filterBloc.add(RemoveFilter(FilterType.dayTimeBlock));
      Navigator.pop(context);
      return;
    }

    filterBloc.add(AddFilter(
      EventFilter(
        type: FilterType.dayTimeBlock,
        criterion: DayTimeBlockCriterion(selectedBlocks: _selectedBlocks),
      ),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date & Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildBlockChip(context, 'saturday_before', 'Saturday before 12h'),
                _buildBlockChip(context, 'saturday_after', 'Saturday after 12h'),
                _buildBlockChip(context, 'sunday_before', 'Sunday before 12h'),
                _buildBlockChip(context, 'sunday_after', 'Sunday after 12h'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _applyFilter(context),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockChip(BuildContext context, String block, String label) {
    final isSelected = _selectedBlocks.contains(block);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleBlock(block),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }
}
