import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/filter_bloc.dart';
import '../models/event_filter.dart';
import '../models/filter_criterion.dart';
import 'simple_date_filter.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<FilterBloc>().add(ClearFilters());
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('Text Search'),
                      onTap: () => _showTextSearchDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.label),
                      title: const Text('Track'),
                      onTap: () => _showTrackDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.room),
                      title: const Text('Room'),
                      onTap: () => _showRoomDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date & Time'),
                      onTap: () => _showSimpleDateFilter(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time Range'),
                      onTap: () => _showTimeRangeDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Next 2 Hours'),
                      onTap: () => _toggleNextHoursFilter(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: const Text('Favorites Only'),
                      onTap: () {
                        context.read<FilterBloc>().add(AddFilter(
                          const EventFilter(
                            type: FilterType.favorites,
                            criterion: FavoritesCriterion(),
                          ),
                        ));
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTextSearchDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter search term'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<FilterBloc>().add(AddFilter(
                  EventFilter(
                    type: FilterType.text,
                    criterion: TextCriterion(query: controller.text),
                  ),
                ));
              }
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showTrackDialog(BuildContext context) async {
    print('DEBUG: Opening track filter dialog');
    // Get database instance
    final database = context.read<FilterBloc>().database;
    print('DEBUG: Got database: $database');
    
    // Fetch all events from database
    final allEvents = await database.eventsDao.getAllEvents();
    print('DEBUG: Fetched ${allEvents.length} events from database');
    
    // Extract unique tracks
    final tracks = allEvents
        .map((e) => e.track)
        .where((track) => track.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    
    print('DEBUG: Extracted ${tracks.length} unique tracks: $tracks');
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Track'),
        content: SizedBox(
          width: double.maxFinite,
          child: tracks.isEmpty
              ? const Center(child: Text('No tracks available'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      title: Text(track),
                      onTap: () {
                        print('DEBUG: Selected track: $track');
                        context.read<FilterBloc>().add(AddFilter(
                          EventFilter(
                            type: FilterType.track,
                            criterion: TrackCriterion(tracks: [track]),
                          ),
                        ));
                        Navigator.pop(dialogContext);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRoomDialog(BuildContext context) async {
    // Get database instance
    final database = context.read<FilterBloc>().database;
    
    // Fetch all events from database
    final allEvents = await database.eventsDao.getAllEvents();
    
    // Extract unique rooms
    final rooms = allEvents
        .map((e) => e.room)
        .where((room) => room.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Room'),
        content: SizedBox(
          width: double.maxFinite,
          child: rooms.isEmpty
              ? const Center(child: Text('No rooms available'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ListTile(
                      title: Text(room),
                      onTap: () {
                        context.read<FilterBloc>().add(AddFilter(
                          EventFilter(
                            type: FilterType.room,
                            criterion: RoomCriterion(rooms: [room]),
                          ),
                        ));
                        Navigator.pop(dialogContext);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSimpleDateFilter(BuildContext context) {
    // Get current selected blocks from filter state
    Set<String>? selectedBlocks;
    final filterState = context.read<FilterBloc>().state;
    if (filterState is FilterApplied) {
      try {
        final dayTimeBlockFilter = filterState.filters.firstWhere(
          (f) => f.type == FilterType.dayTimeBlock,
        );
        if (dayTimeBlockFilter.criterion is DayTimeBlockCriterion) {
          selectedBlocks = (dayTimeBlockFilter.criterion as DayTimeBlockCriterion).selectedBlocks;
        }
      } catch (e) {
        // No existing filter, selectedBlocks remains null
        selectedBlocks = null;
      }
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDateFilter(
        selectedBlocks: selectedBlocks,
      ),
    );
  }

  void _showTimeRangeDialog(BuildContext context) async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    
    // Show start time picker
    startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Select Start Time',
    );
    
    if (startTime == null || !context.mounted) return;
    
    // Show end time picker
    endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: 0),
      helpText: 'Select End Time',
    );
    
    if (endTime == null || !context.mounted) return;
    
    context.read<FilterBloc>().add(AddFilter(
      EventFilter(
        type: FilterType.timeRange,
        criterion: TimeRangeCriterion(
          startHour: startTime.hour,
          endHour: endTime.hour,
        ),
      ),
    ));
    
    Navigator.pop(context);
  }

  void _toggleNextHoursFilter(BuildContext context) {
    final filterBloc = context.read<FilterBloc>();
    final filterState = filterBloc.state;
    
    // Check if the filter already exists
    bool filterExists = false;
    if (filterState is FilterApplied) {
      filterExists = filterState.filters.any(
        (f) => f.type == FilterType.nextHours,
      );
    }
    
    if (filterExists) {
      // Remove the filter
      filterBloc.add(RemoveFilter(FilterType.nextHours));
    } else {
      // Add the filter
      filterBloc.add(AddFilter(
        const EventFilter(
          type: FilterType.nextHours,
          criterion: NextHoursCriterion(hours: 2),
        ),
      ));
    }
    
    Navigator.pop(context);
  }
}
