import 'package:equatable/equatable.dart';

/// Base class for all filter criteria
abstract class FilterCriterion extends Equatable {
  const FilterCriterion();

  /// Checks if an event matches this criterion
  bool matches(dynamic event);

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson();

  /// Get display label for this criterion
  String getLabel();
}

/// Text-based search criterion
class TextCriterion extends FilterCriterion {
  final String query;
  final bool caseSensitive;
  final List<String> searchFields; // title, abstract, description, speakers, etc.

  const TextCriterion({
    required this.query,
    this.caseSensitive = false,
    this.searchFields = const ['title', 'abstract', 'description'],
  });

  @override
  bool matches(dynamic event) {
    final searchQuery = caseSensitive ? query : query.toLowerCase();
    
    for (final field in searchFields) {
      String? fieldValue;
      switch (field) {
        case 'title':
          fieldValue = event.title;
          break;
        case 'abstract':
          fieldValue = event.abstract;
          break;
        case 'description':
          fieldValue = event.description;
          break;
        case 'track':
          fieldValue = event.track;
          break;
        case 'room':
          fieldValue = event.room;
          break;
      }
      
      if (fieldValue != null) {
        final value = caseSensitive ? fieldValue : fieldValue.toLowerCase();
        if (value.contains(searchQuery)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'query': query,
    'caseSensitive': caseSensitive,
    'searchFields': searchFields,
  };

  factory TextCriterion.fromJson(Map<String, dynamic> json) => TextCriterion(
    query: json['query'] as String,
    caseSensitive: json['caseSensitive'] as bool? ?? false,
    searchFields: (json['searchFields'] as List?)?.cast<String>() ?? 
        const ['title', 'abstract', 'description'],
  );

  @override
  String getLabel() => 'Search: "$query"';

  @override
  List<Object?> get props => [query, caseSensitive, searchFields];
}

/// Track-based filter criterion
class TrackCriterion extends FilterCriterion {
  final List<String> tracks;

  const TrackCriterion({required this.tracks});

  @override
  bool matches(dynamic event) {
    print('DEBUG TrackCriterion: Checking event "${event.title}"');
    print('DEBUG TrackCriterion: Event track: "${event.track}"');
    print('DEBUG TrackCriterion: Filter tracks: $tracks');
    final result = tracks.contains(event.track);
    print('DEBUG TrackCriterion: Match result: $result');
    return result;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'track',
    'tracks': tracks,
  };

  factory TrackCriterion.fromJson(Map<String, dynamic> json) => TrackCriterion(
    tracks: (json['tracks'] as List).cast<String>(),
  );

  @override
  String getLabel() => tracks.length == 1 
      ? 'Track: ${tracks.first}' 
      : 'Tracks: ${tracks.length}';

  @override
  List<Object?> get props => [tracks];
}

/// Room-based filter criterion  
class RoomCriterion extends FilterCriterion {
  final List<String> rooms;

  const RoomCriterion({required this.rooms});

  @override
  bool matches(dynamic event) {
    print('DEBUG RoomCriterion: Checking event "${event.title}"');
    print('DEBUG RoomCriterion: Event room: "${event.room}"');
    print('DEBUG RoomCriterion: Filter rooms: $rooms');
    final result = rooms.contains(event.room);
    print('DEBUG RoomCriterion: Match result: $result');
    return result;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'room',
    'rooms': rooms,
  };

  factory RoomCriterion.fromJson(Map<String, dynamic> json) => RoomCriterion(
    rooms: (json['rooms'] as List).cast<String>(),
  );

  @override
  String getLabel() => rooms.length == 1 
      ? 'Room: ${rooms.first}' 
      : 'Rooms: ${rooms.length}';

  @override
  List<Object?> get props => [rooms];
}

/// Date range filter criterion
class DateRangeCriterion extends FilterCriterion {
  final DateTime start;
  final DateTime end;

  const DateRangeCriterion({required this.start, required this.end});

  @override
  bool matches(dynamic event) {
    final eventStart = event.start as DateTime;
    return eventStart.isAfter(start) && eventStart.isBefore(end);
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'dateRange',
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  factory DateRangeCriterion.fromJson(Map<String, dynamic> json) => DateRangeCriterion(
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
  );

  @override
  String getLabel() => 'Date: ${start.month}/${start.day} - ${end.month}/${end.day}';

  @override
  List<Object?> get props => [start, end];
}

/// Time range filter criterion (time of day)
class TimeRangeCriterion extends FilterCriterion {
  final int startHour;
  final int endHour;

  const TimeRangeCriterion({required this.startHour, required this.endHour});

  @override
  bool matches(dynamic event) {
    final eventStart = event.start as DateTime;
    final hour = eventStart.hour;
    return hour >= startHour && hour < endHour;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'timeRange',
    'startHour': startHour,
    'endHour': endHour,
  };

  factory TimeRangeCriterion.fromJson(Map<String, dynamic> json) => TimeRangeCriterion(
    startHour: json['startHour'] as int,
    endHour: json['endHour'] as int,
  );

  @override
  String getLabel() => 'Time: ${startHour}:00 - ${endHour}:00';

  @override
  List<Object?> get props => [startHour, endHour];
}

/// Duration filter criterion
class DurationCriterion extends FilterCriterion {
  final Duration minDuration;
  final Duration maxDuration;

  const DurationCriterion({required this.minDuration, required this.maxDuration});

  @override
  bool matches(dynamic event) {
    final duration = event.duration as Duration;
    return duration >= minDuration && duration <= maxDuration;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'duration',
    'minDuration': minDuration.inMinutes,
    'maxDuration': maxDuration.inMinutes,
  };

  factory DurationCriterion.fromJson(Map<String, dynamic> json) => DurationCriterion(
    minDuration: Duration(minutes: json['minDuration'] as int),
    maxDuration: Duration(minutes: json['maxDuration'] as int),
  );

  @override
  String getLabel() => 'Duration: ${minDuration.inMinutes}-${maxDuration.inMinutes}min';

  @override
  List<Object?> get props => [minDuration, maxDuration];
}

/// Favorites filter criterion
class FavoritesCriterion extends FilterCriterion {
  final bool onlyFavorites;

  const FavoritesCriterion({this.onlyFavorites = true});

  @override
  bool matches(dynamic event) {
    // This will be checked against favorites list in the BLoC
    return onlyFavorites;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'favorites',
    'onlyFavorites': onlyFavorites,
  };

  factory FavoritesCriterion.fromJson(Map<String, dynamic> json) => FavoritesCriterion(
    onlyFavorites: json['onlyFavorites'] as bool? ?? true,
  );

  @override
  String getLabel() => 'Favorites only';

  @override
  List<Object?> get props => [onlyFavorites];
}

/// Next hours filter criterion
/// Shows events starting within the next N hours from current time
class NextHoursCriterion extends FilterCriterion {
  final int hours;

  const NextHoursCriterion({this.hours = 2});

  @override
  bool matches(dynamic event) {
    final now = DateTime.now();
    final endTime = now.add(Duration(hours: hours));
    
    // Handle different event types
    DateTime? eventStart;
    if (event.start != null) {
      eventStart = event.start as DateTime;
    } else if (event.startTime != null) {
      eventStart = event.startTime as DateTime;
    } else {
      return false; // Cannot determine event time
    }
    
    // Check if event starts between now and end time
    // Include events that have already started but are still within the time window
    return eventStart.isAfter(now.subtract(const Duration(minutes: 1))) && 
           eventStart.isBefore(endTime.add(const Duration(minutes: 1)));
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'nextHours',
    'hours': hours,
  };

  factory NextHoursCriterion.fromJson(Map<String, dynamic> json) => NextHoursCriterion(
    hours: json['hours'] as int? ?? 2,
  );

  @override
  String getLabel() => hours == 2 ? 'Next 2 hours' : 'Next $hours hours';

  @override
  List<Object?> get props => [hours];
}

/// Day and time block filter criterion
/// Combines day (Saturday/Sunday) with time block (before/after 12h)
class DayTimeBlockCriterion extends FilterCriterion {
  final Set<String> selectedBlocks; // e.g., ['saturday_before', 'sunday_after']

  const DayTimeBlockCriterion({required this.selectedBlocks});

  @override
  bool matches(dynamic event) {
    if (selectedBlocks.isEmpty) return true;
    
    // Handle different event types
    DateTime eventStart;
    if (event.start != null) {
      eventStart = event.start as DateTime;
    } else if (event.startTime != null) {
      eventStart = event.startTime as DateTime;
    } else {
      return false; // Cannot determine event time
    }
    
    final weekday = eventStart.weekday;
    final hour = eventStart.hour;
    
    // Check if event matches any selected block
    for (final block in selectedBlocks) {
      if (_matchesBlock(block, weekday, hour)) {
        return true;
      }
    }
    
    return false;
  }

  bool _matchesBlock(String block, int weekday, int hour) {
    final isSaturday = weekday == DateTime.saturday;
    final isSunday = weekday == DateTime.sunday;
    final isBefore12 = hour < 12;
    final isAfter12 = hour >= 12;
    
    switch (block) {
      case 'saturday_before':
        return isSaturday && isBefore12;
      case 'saturday_after':
        return isSaturday && isAfter12;
      case 'sunday_before':
        return isSunday && isBefore12;
      case 'sunday_after':
        return isSunday && isAfter12;
      default:
        return false;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'dayTimeBlock',
    'selectedBlocks': selectedBlocks.toList(),
  };

  factory DayTimeBlockCriterion.fromJson(Map<String, dynamic> json) => DayTimeBlockCriterion(
    selectedBlocks: (json['selectedBlocks'] as List?)?.cast<String>().toSet() ?? {},
  );

  @override
  String getLabel() {
    if (selectedBlocks.isEmpty) return 'Any time';
    if (selectedBlocks.length == 1) {
      return _getBlockLabel(selectedBlocks.first);
    }
    return '${selectedBlocks.length} time blocks';
  }

  String _getBlockLabel(String block) {
    switch (block) {
      case 'saturday_before':
        return 'Saturday before 12h';
      case 'saturday_after':
        return 'Saturday after 12h';
      case 'sunday_before':
        return 'Sunday before 12h';
      case 'sunday_after':
        return 'Sunday after 12h';
      default:
        return block;
    }
  }

  @override
  List<Object?> get props => [selectedBlocks];
}
