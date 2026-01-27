import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/journey_models.dart';
import '../bloc/journey_bloc.dart';
import '../bloc/journey_event.dart';
import '../../../../presentation/screens/event_detail_screen.dart';
import '../../../../domain/entities/event.dart';

class JourneyTimelineWidget extends StatelessWidget {
  final DateTime date;
  final List<JourneyItem> events;
  final List<JourneyItem> candidates;
  final List<Conflict> conflicts;

  const JourneyTimelineWidget({
    super.key,
    required this.date,
    required this.events,
    this.candidates = const [],
    required this.conflicts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('${events.length} events'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ],
            ),
          ),

          // Timeline Events - Merge planned and candidate events
          ..._buildTimelineItems(context),
        ],
      ),
    );
  }

  bool _hasConflict(JourneyItem event) {
    return conflicts.any((c) => c.affectedEvents.any((e) => e.id == event.id));
  }

  List<Conflict> _getConflicts(JourneyItem event) {
    return conflicts.where((c) => c.affectedEvents.any((e) => e.id == event.id)).toList();
  }

  List<Widget> _buildTimelineItems(BuildContext context) {
    // Merge and sort all items by time
    final allItems = <({JourneyItem item, bool isCandidate})>[];
    
    for (final event in events) {
      allItems.add((item: event, isCandidate: false));
    }
    
    for (final candidate in candidates) {
      // Only add if same day
      if (candidate.startTime.year == date.year &&
          candidate.startTime.month == date.month &&
          candidate.startTime.day == date.day) {
        allItems.add((item: candidate, isCandidate: true));
      }
    }
    
    // Sort by start time
    allItems.sort((a, b) => a.item.startTime.compareTo(b.item.startTime));
    
    final widgets = <Widget>[];
    
    for (int i = 0; i < allItems.length; i++) {
      final current = allItems[i];
      final isLast = i == allItems.length - 1;
      
      Duration? breakDuration;
      if (!isLast) {
        final next = allItems[i + 1];
        breakDuration = next.item.startTime.difference(current.item.endTime);
      }
      
      widgets.add(
        _TimelineEventCard(
          event: current.item,
          isCandidate: current.isCandidate,
          hasConflict: _hasConflict(current.item),
          conflicts: _getConflicts(current.item),
          showBreak: !isLast,
          breakDuration: breakDuration,
          plannedEvents: events,
        ),
      );
    }
    
    return widgets;
  }
}

class _TimelineEventCard extends StatelessWidget {
  final JourneyItem event;
  final bool isCandidate;
  final bool hasConflict;
  final List<Conflict> conflicts;
  final bool showBreak;
  final Duration? breakDuration;
  final List<JourneyItem> plannedEvents;

  const _TimelineEventCard({
    required this.event,
    required this.isCandidate,
    required this.hasConflict,
    required this.conflicts,
    required this.showBreak,
    this.breakDuration,
    required this.plannedEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // Navigate to event detail
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(
                  event: Event(
                    id: event.eventId,
                    title: event.eventTitle,
                    subtitle: '',
                    abstract: '',
                    description: '',
                    start: event.startTime,
                    date: event.startTime,
                    duration: event.duration.inMinutes,
                    room: event.room,
                    track: event.track,
                    url: '',
                    people: const [],
                    links: const [],
                    attachments: const [],
                    isSync: false,
                  ),
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isCandidate 
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
              border: isCandidate 
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    )
                  : null,
              borderRadius: isCandidate ? BorderRadius.circular(8) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline line
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isCandidate
                              ? Theme.of(context).colorScheme.primary
                              : (hasConflict 
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.tertiary),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCandidate 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                      if (showBreak)
                        Container(
                          width: 2,
                          height: 60,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Event details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Candidate badge
                        if (isCandidate)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmark,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'FAVORITE - TAP TO ADD TO JOURNEY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Time
                        Text(
                          '${DateFormat.Hm().format(event.startTime)} - ${DateFormat.Hm().format(event.endTime)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCandidate
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Title
                      Text(
                        event.eventTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Location and track
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${event.room}  •  Building ${event.building}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.track,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Priority stars
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < (6 - event.priority) ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Priority ${event.priority}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      // Conflicts
                      if (hasConflict) ...[
                        const SizedBox(height: 12),
                        ...conflicts.map((conflict) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getConflictColor(context, conflict.severity).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getConflictColor(context, conflict.severity),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getConflictIcon(conflict.type),
                                  size: 16,
                                  color: _getConflictColor(context, conflict.severity),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    conflict.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getConflictColor(context, conflict.severity),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Notes
                      if (event.notes != null && event.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.notes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                if (isCandidate)
                  _AddToCandidateButton(
                    event: event,
                    plannedEvents: plannedEvents,
                  )
                else
                  PopupMenuButton<String>(
                  onSelected: (value) {
                    final bloc = context.read<JourneyBloc>();
                    switch (value) {
                      case 'wishlist':
                        bloc.add(MoveToWishlist(event.id));
                        break;
                      case 'remove':
                        bloc.add(RemoveFromJourney(event.id));
                        break;
                      case 'priority':
                        _showPriorityDialog(context, event);
                        break;
                      case 'notes':
                        _showNotesDialog(context, event);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'wishlist',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border),
                          SizedBox(width: 8),
                          Text('Move to wishlist'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'priority',
                      child: Row(
                        children: [
                          Icon(Icons.star),
                          SizedBox(width: 8),
                          Text('Change priority'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notes',
                      child: Row(
                        children: [
                          Icon(Icons.note_add),
                          SizedBox(width: 8),
                          Text('Add notes'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),

        // Break indicator
        if (showBreak && breakDuration != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 28),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.coffee,
                          size: 16,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${breakDuration!.inMinutes} min break',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getConflictColor(BuildContext context, ConflictSeverity severity) {
    switch (severity) {
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

  IconData _getConflictIcon(ConflictType type) {
    switch (type) {
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

  void _showPriorityDialog(BuildContext context, JourneyItem event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final priority = index + 1;
            return RadioListTile<int>(
              title: Text('Priority $priority'),
              value: priority,
              groupValue: event.priority,
              onChanged: (value) {
                if (value != null) {
                  context.read<JourneyBloc>().add(
                        UpdatePriority(journeyItemId: event.id, priority: value),
                      );
                  Navigator.pop(context);
                }
              },
            );
          }),
        ),
      ),
    );
  }

  void _showNotesDialog(BuildContext context, JourneyItem event) {
    final controller = TextEditingController(text: event.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<JourneyBloc>().add(
                    UpdateNotes(journeyItemId: event.id, notes: controller.text),
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AddToCandidateButton extends StatelessWidget {
  final JourneyItem event;
  final List<JourneyItem> plannedEvents;

  const _AddToCandidateButton({
    required this.event,
    required this.plannedEvents,
  });

  List<String> _detectPotentialConflicts() {
    final conflicts = <String>[];
    
    for (final planned in plannedEvents) {
      // Time overlap
      if (event.startTime.isBefore(planned.endTime) && 
          event.endTime.isAfter(planned.startTime)) {
        conflicts.add('⚠️ Time conflict with "${planned.eventTitle}"');
        continue;
      }
      
      // Check if this event comes right after the planned one
      if (planned.endTime.isBefore(event.startTime)) {
        final gap = event.startTime.difference(planned.endTime);
        
        // Different buildings - need transition time
        if (planned.building != event.building) {
          final neededTime = Duration(minutes: 10); // 10 min buffer
          if (gap < neededTime) {
            conflicts.add('⚠️ Tight transition from "${planned.eventTitle}" in ${planned.building} (${gap.inMinutes} min)');
          }
        }
      }
      
      // Check if this event comes right before the planned one
      if (event.endTime.isBefore(planned.startTime)) {
        final gap = planned.startTime.difference(event.endTime);
        
        // Different buildings - need transition time
        if (event.building != planned.building) {
          final neededTime = Duration(minutes: 10);
          if (gap < neededTime) {
            conflicts.add('⚠️ Tight transition to "${planned.eventTitle}" in ${planned.building} (${gap.inMinutes} min)');
          }
        }
      }
    }
    
    return conflicts;
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _detectPotentialConflicts();
    final hasConflicts = conflicts.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasConflicts) ...[
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: conflicts.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
        ElevatedButton.icon(
          onPressed: () {
            if (hasConflicts) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Add to Journey'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This event has potential conflicts:'),
                      const SizedBox(height: 12),
                      ...conflicts.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $c', style: const TextStyle(fontSize: 13)),
                      )),
                      const SizedBox(height: 12),
                      const Text('Do you still want to add it to your journey?'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                      ElevatedButton(
                      onPressed: () {
                        context.read<JourneyBloc>().add(AddToJourney(eventId: event.eventId));
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      child: const Text('Add Anyway'),
                    ),
                  ],
                ),
              );
            } else {
              context.read<JourneyBloc>().add(AddToJourney(eventId: event.eventId));
            }
          },
          icon: Icon(hasConflicts ? Icons.warning : Icons.add, size: 16),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasConflicts 
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.primary,
            foregroundColor: hasConflicts
                ? Theme.of(context).colorScheme.onErrorContainer
                : Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}
