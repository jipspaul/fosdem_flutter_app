import 'package:flutter/material.dart';
import '../../domain/models/journey_models.dart';

class ConflictCardWidget extends StatelessWidget {
  final Conflict conflict;

  const ConflictCardWidget({super.key, required this.conflict});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getSeverityColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(),
                size: 20,
                color: _getSeverityColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict.description,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getSeverityColor(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(BuildContext context) {
    switch (conflict.severity) {
      case ConflictSeverity.critical:
        return Theme.of(context).colorScheme.error;
      case ConflictSeverity.high:
        return Theme.of(context).colorScheme.errorContainer;
      case ConflictSeverity.medium:
        return Theme.of(context).colorScheme.tertiary;
      case ConflictSeverity.low:
        return Theme.of(context).colorScheme.primary;
      case ConflictSeverity.info:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  IconData _getTypeIcon() {
    switch (conflict.type) {
      case ConflictType.timeOverlap:
        return Icons.error_outline;
      case ConflictType.impossibleTransition:
        return Icons.directions_walk;
      case ConflictType.backToBackNoBreak:
        return Icons.coffee;
      case ConflictType.tooManyEvents:
        return Icons.event_busy;
      case ConflictType.priorityConflict:
        return Icons.priority_high;
    }
  }
}
