import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/domain/entities/event.dart';
import 'package:fosdem_flutter/domain/entities/person.dart';
import 'package:fosdem_flutter/domain/entities/link.dart';
import 'package:fosdem_flutter/domain/entities/attachment.dart';
import 'package:fosdem_flutter/domain/entities/filter_criteria.dart';
import 'package:fosdem_flutter/domain/services/event_filter_service.dart';

void main() {
  late EventFilterService filterService;
  late List<Event> testEvents;

  setUp(() {
    filterService = EventFilterService();
    
    // Create test events
    final saturdayMorning = DateTime(2025, 2, 1, 9, 0);
    final saturdayAfternoon = DateTime(2025, 2, 1, 14, 0);
    final sundayMorning = DateTime(2025, 2, 2, 10, 0);
    
    testEvents = [
      Event(
        id: 1,
        title: 'Keynote: The Future of Open Source',
        track: 'Keynotes',
        room: 'Janson',
        date: DateTime(2025, 2, 1),
        start: saturdayMorning,
        duration: 60,
        abstract: 'A look into the future',
        people: const [Person(id: 1, name: 'John Doe')],
        links: const [Link(url: 'https://video.fosdem.org/test', title: 'Video', isVideo: true)],
        attachments: const [],
      ),
      Event(
        id: 2,
        title: 'Building Web Apps with Flutter',
        track: 'Flutter',
        room: 'H.2215',
        date: DateTime(2025, 2, 1),
        start: saturdayAfternoon,
        duration: 45,
        abstract: 'Learn Flutter for web',
        people: const [Person(id: 2, name: 'Jane Smith')],
        links: const [],
        attachments: const [Attachment(url: 'slides.pdf', title: 'Slides', type: AttachmentType.slides)],
      ),
      Event(
        id: 3,
        title: 'Rust for Beginners',
        track: 'Rust',
        room: 'K.1.105',
        date: DateTime(2025, 2, 2),
        start: sundayMorning,
        duration: 30,
        people: const [Person(id: 3, name: 'Bob Johnson')],
        links: const [],
        attachments: const [],
      ),
    ];
  });

  group('FilterCriteria', () {
    test('hasActiveFilters returns false for empty criteria', () {
      const criteria = FilterCriteria();
      expect(criteria.hasActiveFilters, false);
    });

    test('hasActiveFilters returns true when filters are set', () {
      final criteria = FilterCriteria(
        selectedTracks: {'Flutter'},
      );
      expect(criteria.hasActiveFilters, true);
    });

    test('activeFilterCount counts correctly', () {
      final criteria = FilterCriteria(
        selectedTracks: {'Flutter', 'Rust'},
        selectedRooms: {'H.2215'},
        hasVideo: true,
      );
      expect(criteria.activeFilterCount, 3);
    });

    test('copyWith works correctly', () {
      const criteria = FilterCriteria(
        selectedTracks: {'Flutter'},
      );
      final updated = criteria.copyWith(
        selectedRooms: {'H.2215'},
      );
      expect(updated.selectedTracks, {'Flutter'});
      expect(updated.selectedRooms, {'H.2215'});
    });

    test('clear removes all filters', () {
      final criteria = FilterCriteria(
        selectedTracks: {'Flutter'},
        selectedRooms: {'H.2215'},
        hasVideo: true,
      );
      final cleared = criteria.clear();
      expect(cleared.hasActiveFilters, false);
    });
  });

  group('TimeRange', () {
    test('contains returns true for time in range', () {
      const timeRange = TimeRange(
        startHour: 9,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
      );
      final time = DateTime(2025, 2, 1, 10, 30);
      expect(timeRange.contains(time), true);
    });

    test('contains returns false for time outside range', () {
      const timeRange = TimeRange(
        startHour: 9,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
      );
      final time = DateTime(2025, 2, 1, 14, 0);
      expect(timeRange.contains(time), false);
    });

    test('toString formats correctly', () {
      const timeRange = TimeRange(
        startHour: 9,
        startMinute: 30,
        endHour: 12,
        endMinute: 45,
      );
      expect(timeRange.toString(), '09:30 - 12:45');
    });
  });

  group('DurationRange', () {
    test('contains returns true for duration in range', () {
      const durationRange = DurationRange(minDuration: 30, maxDuration: 60);
      expect(durationRange.contains(45), true);
    });

    test('contains returns false for duration outside range', () {
      const durationRange = DurationRange(minDuration: 30, maxDuration: 60);
      expect(durationRange.contains(90), false);
    });
  });

  group('EventFilterService - Basic Filters', () {
    test('returns all events when no filters applied', () {
      const criteria = FilterCriteria();
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 3);
    });

    test('filters by track', () {
      final criteria = FilterCriteria(
        selectedTracks: {'Flutter'},
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
      expect(filtered[0].track, 'Flutter');
    });

    test('filters by multiple tracks', () {
      final criteria = FilterCriteria(
        selectedTracks: {'Flutter', 'Rust'},
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 2);
    });

    test('filters by room', () {
      final criteria = FilterCriteria(
        selectedRooms: {'Janson'},
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
      expect(filtered[0].room, 'Janson');
    });

    test('filters by date', () {
      final criteria = FilterCriteria(
        selectedDates: {DateTime(2025, 2, 1)},
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 2);
    });

    test('filters by day (Saturday)', () {
      final criteria = FilterCriteria(
        selectedDays: {1}, // 1 = Saturday
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 2);
    });

    test('filters by day (Sunday)', () {
      final criteria = FilterCriteria(
        selectedDays: {2}, // 2 = Sunday
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
    });
  });

  group('EventFilterService - Advanced Filters', () {
    test('filters by time range', () {
      final criteria = FilterCriteria(
        timeRange: const TimeRange(
          startHour: 9,
          startMinute: 0,
          endHour: 12,
          endMinute: 0,
        ),
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 2); // Morning events
    });

    test('filters by duration range', () {
      final criteria = FilterCriteria(
        durationRange: const DurationRange(minDuration: 40, maxDuration: 60),
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 2); // 45 and 60 minute events
    });

    test('filters by speaker', () {
      final criteria = FilterCriteria(
        selectedSpeakers: {'Jane Smith'},
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Building Web Apps with Flutter');
    });

    test('filters by hasVideo', () {
      final criteria = FilterCriteria(
        hasVideo: true,
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
      expect(filtered[0].hasVideo, true);
    });

    test('filters by hasAttachments', () {
      final criteria = FilterCriteria(
        hasAttachments: true,
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
      expect(filtered[0].hasAttachments, true);
    });

    test('filters by search text in title', () {
      final criteria = FilterCriteria(
        searchText: 'flutter',
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Building Web Apps with Flutter');
    });

    test('filters by search text in speaker name', () {
      final criteria = FilterCriteria(
        searchText: 'jane',
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
    });

    test('filters by search text in track', () {
      final criteria = FilterCriteria(
        searchText: 'rust',
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
    });
  });

  group('EventFilterService - Combined Filters', () {
    test('applies multiple filters together', () {
      final criteria = FilterCriteria(
        selectedTracks: {'Flutter', 'Keynotes'},
        hasVideo: true,
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Keynote: The Future of Open Source');
    });

    test('returns empty list when no events match all criteria', () {
      final criteria = FilterCriteria(
        selectedTracks: {'Flutter'},
        hasVideo: true,
      );
      final filtered = filterService.applyFilters(testEvents, criteria);
      expect(filtered.length, 0);
    });
  });

  group('EventFilterService - Helper Methods', () {
    test('getAvailableTracks returns all unique tracks', () {
      final tracks = filterService.getAvailableTracks(testEvents);
      expect(tracks.length, 3);
      expect(tracks, containsAll(['Keynotes', 'Flutter', 'Rust']));
    });

    test('getAvailableRooms returns all unique rooms', () {
      final rooms = filterService.getAvailableRooms(testEvents);
      expect(rooms.length, 3);
      expect(rooms, containsAll(['Janson', 'H.2215', 'K.1.105']));
    });

    test('getAvailableDates returns all unique dates', () {
      final dates = filterService.getAvailableDates(testEvents);
      expect(dates.length, 2);
    });

    test('getAvailableSpeakers returns all unique speakers', () {
      final speakers = filterService.getAvailableSpeakers(testEvents);
      expect(speakers.length, 3);
      expect(speakers, containsAll(['John Doe', 'Jane Smith', 'Bob Johnson']));
    });

    test('getDurationStats calculates correctly', () {
      final stats = filterService.getDurationStats(testEvents);
      expect(stats.min, 30);
      expect(stats.max, 60);
      expect(stats.average, 45);
    });

    test('getDurationStats handles empty list', () {
      final stats = filterService.getDurationStats([]);
      expect(stats.min, 0);
      expect(stats.max, 0);
      expect(stats.average, 0);
    });
  });

  group('EventFilterService - Sorting', () {
    test('sorts by start time', () {
      final sorted = filterService.sortEvents(testEvents, SortCriteria.startTime);
      expect(sorted[0].start.hour, 9); // Saturday 9am
      expect(sorted[1].start.hour, 14); // Saturday 2pm
      expect(sorted[2].start.hour, 10); // Sunday 10am
    });

    test('sorts by title', () {
      final sorted = filterService.sortEvents(testEvents, SortCriteria.title);
      expect(sorted[0].title, 'Building Web Apps with Flutter');
      expect(sorted[2].title, 'Rust for Beginners');
    });

    test('sorts by track', () {
      final sorted = filterService.sortEvents(testEvents, SortCriteria.track);
      expect(sorted[0].track, 'Flutter');
      expect(sorted[2].track, 'Rust');
    });

    test('sorts by duration', () {
      final sorted = filterService.sortEvents(testEvents, SortCriteria.duration);
      expect(sorted[0].duration, 30);
      expect(sorted[2].duration, 60);
    });
  });
}
