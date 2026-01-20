import '../../../domain/entities/event.dart';
import 'filter_models.dart';

class FilterSuggestionsService {
  List<FilterSuggestion> generateSuggestions(
    List<Event> events,
    EventFilter currentFilter,
  ) {
    final suggestions = <FilterSuggestion>[];
    
    // Popular tracks suggestion
    final trackCounts = _countTracks(events);
    if (trackCounts.isNotEmpty) {
      final topTrack = trackCounts.entries.first;
      suggestions.add(FilterSuggestion(
        id: 'popular_track',
        title: 'Popular Track',
        description: '${topTrack.value} events in ${topTrack.key}',
        filter: currentFilter.copyWith(
          tracks: {topTrack.key},
        ),
        icon: '🔥',
      ));
    }
    
    // Happening now suggestion
    final now = DateTime.now();
    final happeningNow = events.where((e) => 
      e.start.isBefore(now) && e.end.isAfter(now)
    ).length;
    if (happeningNow > 0) {
      suggestions.add(FilterSuggestion(
        id: 'happening_now',
        title: 'Happening Now',
        description: '$happeningNow events in progress',
        filter: currentFilter.copyWith(
          timeRange: TimeRange(
            start: now.subtract(const Duration(minutes: 30)),
            end: now.add(const Duration(minutes: 30)),
          ),
        ),
        icon: '⏰',
      ));
    }
    
    // Coming up soon
    final comingSoon = events.where((e) => 
      e.start.isAfter(now) && 
      e.start.isBefore(now.add(const Duration(hours: 1)))
    ).length;
    if (comingSoon > 0) {
      suggestions.add(FilterSuggestion(
        id: 'coming_soon',
        title: 'Coming Up Soon',
        description: '$comingSoon events in next hour',
        filter: currentFilter.copyWith(
          timeRange: TimeRange(
            start: now,
            end: now.add(const Duration(hours: 1)),
          ),
        ),
        icon: '🔜',
      ));
    }
    
    // Short talks (< 30 minutes)
    final shortTalks = events.where((e) => 
      e.duration <= 30
    ).length;
    if (shortTalks > 5) {
      suggestions.add(FilterSuggestion(
        id: 'short_talks',
        title: 'Quick Sessions',
        description: '$shortTalks talks under 30 minutes',
        filter: currentFilter.copyWith(
          durationRange: DurationRange(
            min: Duration.zero,
            max: const Duration(minutes: 30),
          ),
        ),
        icon: '⚡',
      ));
    }
    
    // Popular rooms
    final roomCounts = _countRooms(events);
    if (roomCounts.isNotEmpty) {
      final topRoom = roomCounts.entries.first;
      suggestions.add(FilterSuggestion(
        id: 'popular_room',
        title: 'Busy Room',
        description: '${topRoom.value} events in ${topRoom.key}',
        filter: currentFilter.copyWith(
          rooms: {topRoom.key},
        ),
        icon: '🏛️',
      ));
    }
    
    // Weekend events
    final weekend = events.where((e) => 
      e.start.weekday == DateTime.saturday || 
      e.start.weekday == DateTime.sunday
    ).length;
    if (weekend > 0) {
      suggestions.add(FilterSuggestion(
        id: 'weekend',
        title: 'Weekend Events',
        description: '$weekend events on weekend',
        filter: currentFilter.copyWith(
          days: {DateTime.saturday, DateTime.sunday},
        ),
        icon: '📅',
      ));
    }
    
    return suggestions;
  }
  
  Map<String, int> _countTracks(List<Event> events) {
    final counts = <String, int>{};
    for (final event in events) {
      if (event.track.isNotEmpty) {
        counts[event.track] = (counts[event.track] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }
  
  Map<String, int> _countRooms(List<Event> events) {
    final counts = <String, int>{};
    for (final event in events) {
      if (event.room.isNotEmpty) {
        counts[event.room] = (counts[event.room] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }
  
  List<SavedFilter> getRecentFilters() {
    // TODO: Load from shared preferences
    return [];
  }
  
  Future<void> saveFilter(SavedFilter filter) async {
    // TODO: Save to shared preferences
  }
  
  Future<void> deleteFilter(String filterId) async {
    // TODO: Delete from shared preferences
  }
}
