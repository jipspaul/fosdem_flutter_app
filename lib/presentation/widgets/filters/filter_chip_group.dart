import 'package:flutter/material.dart';

class FilterChipGroup extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onChanged;
  final bool multiSelect;
  final IconData? icon;

  const FilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selectedOptions,
    required this.onChanged,
    this.multiSelect = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  List<String> newSelection;
                  if (multiSelect) {
                    newSelection = List.from(selectedOptions);
                    if (selected) {
                      newSelection.add(option);
                    } else {
                      newSelection.remove(option);
                    }
                  } else {
                    newSelection = selected ? [option] : [];
                  }
                  onChanged(newSelection);
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
