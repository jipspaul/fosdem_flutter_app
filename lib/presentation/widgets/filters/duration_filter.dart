import 'package:flutter/material.dart';

class DurationFilter extends StatelessWidget {
  final String label;
  final int? minDuration;
  final int? maxDuration;
  final Function(int?) onMinDurationChanged;
  final Function(int?) onMaxDurationChanged;
  final IconData? icon;

  const DurationFilter({
    super.key,
    required this.label,
    this.minDuration,
    this.maxDuration,
    required this.onMinDurationChanged,
    required this.onMaxDurationChanged,
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
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: minDuration,
                  decoration: const InputDecoration(
                    labelText: 'Min Duration',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(12, (i) => (i + 1) * 15).map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('${minutes}m'),
                      ),
                    ),
                  ],
                  onChanged: onMinDurationChanged,
                ),
              ),
              const SizedBox(width: 8),
              const Text('to'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: maxDuration,
                  decoration: const InputDecoration(
                    labelText: 'Max Duration',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(12, (i) => (i + 1) * 15).map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('${minutes}m'),
                      ),
                    ),
                  ],
                  onChanged: onMaxDurationChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
