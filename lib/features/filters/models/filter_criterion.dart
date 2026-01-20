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
