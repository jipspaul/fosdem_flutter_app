import '../entities/event.dart';
import '../entities/filter_criteria.dart';

/// Service to apply filters to events
class EventFilterService {
  /// Apply filter criteria to a list of events
  List<Event> applyFilters(List<Event> events, FilterCriteria criteria) {
    if (!criteria.hasActiveFilters) {
      return events;
    }

    return events.where((event) {
      // Track filter
      if (criteria.selectedTracks.isNotEmpty &&
          !criteria.selectedTracks.contains(event.track)) {
        return false;
      }

      // Room filter
      if (criteria.selectedRooms.isNotEmpty &&
          !criteria.selectedRooms.contains(event.room)) {
        return false;
      }

      // Date filter
      if (criteria.selectedDates.isNotEmpty) {
        final eventDate = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );
        if (!criteria.selectedDates.any((date) {
          final filterDate = DateTime(date.year, date.month, date.day);
          return filterDate == eventDate;
        })) {
          return false;
        }
      }

      // Day filter (1 = Saturday, 2 = Sunday)
      if (criteria.selectedDays.isNotEmpty) {
        // Assuming FOSDEM is on Saturday (6) and Sunday (7)
        final weekday = event.date.weekday;
        final dayNumber = weekday == DateTime.saturday ? 1 : 2;
        if (!criteria.selectedDays.contains(dayNumber)) {
          return false;
        }
      }

      // Time range filter
      if (criteria.timeRange != null) {
        if (!criteria.timeRange!.contains(event.start)) {
          return false;
        }
      }

      // Duration filter
      if (criteria.durationRange != null) {
        if (!criteria.durationRange!.contains(event.duration)) {
          return false;
        }
      }

      // Speaker filter
      if (criteria.selectedSpeakers.isNotEmpty) {
        final eventSpeakers = event.people.map((p) => p.name).toSet();
        if (!criteria.selectedSpeakers.any(eventSpeakers.contains)) {
          return false;
        }
      }

      // Has video filter
      if (criteria.hasVideo != null) {
        if (criteria.hasVideo! != event.hasVideo) {
          return false;
        }
      }

      // Has attachments filter
      if (criteria.hasAttachments != null) {
        if (criteria.hasAttachments! != event.hasAttachments) {
          return false;
        }
      }

      // Status filter
      if (criteria.status != EventStatus.all) {
        switch (criteria.status) {
          case EventStatus.now:
            if (!event.isHappeningNow()) return false;
            break;
          case EventStatus.upcoming:
            if (!event.isUpcoming()) return false;
            break;
          case EventStatus.past:
            if (!event.isPast()) return false;
            break;
          case EventStatus.all:
            break;
        }
      }

      // Search text filter (searches in title, abstract, description, speaker names)
      if (criteria.searchText != null && criteria.searchText!.isNotEmpty) {
        final searchLower = criteria.searchText!.toLowerCase();
        final titleMatch = event.title.toLowerCase().contains(searchLower);
        final abstractMatch =
            event.abstract?.toLowerCase().contains(searchLower) ?? false;
        final descriptionMatch =
            event.description?.toLowerCase().contains(searchLower) ?? false;
        final speakerMatch = event.people
            .any((p) => p.name.toLowerCase().contains(searchLower));
        final trackMatch = event.track.toLowerCase().contains(searchLower);
        final roomMatch = event.room.toLowerCase().contains(searchLower);

        if (!titleMatch &&
            !abstractMatch &&
            !descriptionMatch &&
            !speakerMatch &&
            !trackMatch &&
            !roomMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Get all unique tracks from events
  Set<String> getAvailableTracks(List<Event> events) {
    return events.map((e) => e.track).toSet();
  }

  /// Get all unique rooms from events
  Set<String> getAvailableRooms(List<Event> events) {
    return events.map((e) => e.room).toSet();
  }

  /// Get all unique dates from events
  Set<DateTime> getAvailableDates(List<Event> events) {
    return events.map((e) {
      return DateTime(e.date.year, e.date.month, e.date.day);
    }).toSet();
  }

  /// Get all unique speakers from events
  Set<String> getAvailableSpeakers(List<Event> events) {
    final speakers = <String>{};
    for (final event in events) {
      for (final person in event.people) {
        speakers.add(person.name);
      }
    }
    return speakers;
  }

  /// Get duration statistics
  DurationStats getDurationStats(List<Event> events) {
    if (events.isEmpty) {
      return const DurationStats(min: 0, max: 0, average: 0);
    }

    final durations = events.map((e) => e.duration).toList();
    final min = durations.reduce((a, b) => a < b ? a : b);
    final max = durations.reduce((a, b) => a > b ? a : b);
    final average = durations.reduce((a, b) => a + b) / durations.length;

    return DurationStats(min: min, max: max, average: average.round());
  }

  /// Sort events by various criteria
  List<Event> sortEvents(List<Event> events, SortCriteria criteria) {
    final sorted = List<Event>.from(events);
    
    switch (criteria) {
      case SortCriteria.startTime:
        sorted.sort((a, b) => a.start.compareTo(b.start));
        break;
      case SortCriteria.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortCriteria.track:
        sorted.sort((a, b) => a.track.compareTo(b.track));
        break;
      case SortCriteria.room:
        sorted.sort((a, b) => a.room.compareTo(b.room));
        break;
      case SortCriteria.duration:
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }

    return sorted;
  }
}

/// Duration statistics
class DurationStats {
  final int min;
  final int max;
  final int average;

  const DurationStats({
    required this.min,
    required this.max,
    required this.average,
  });
}

/// Sort criteria enum
enum SortCriteria {
  startTime,
  title,
  track,
  room,
  duration,
}
