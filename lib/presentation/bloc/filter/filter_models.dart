import 'package:equatable/equatable.dart';

class FilterSuggestion extends Equatable {
  final String id;
  final String title;
  final String description;
  final EventFilter filter;
  final String icon;

  const FilterSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.filter,
    required this.icon,
  });

  @override
  List<Object?> get props => [id, title, description, filter, icon];
}

class TimeRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const TimeRange({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

class DurationRange extends Equatable {
  final Duration min;
  final Duration max;

  const DurationRange({
    required this.min,
    required this.max,
  });

  @override
  List<Object?> get props => [min, max];
}

class EventFilter extends Equatable {
  final Set<String> tracks;
  final Set<String> rooms;
  final TimeRange? timeRange;
  final DurationRange? durationRange;
  final Set<int> days;

  const EventFilter({
    this.tracks = const {},
    this.rooms = const {},
    this.timeRange,
    this.durationRange,
    this.days = const {},
  });

  EventFilter copyWith({
    Set<String>? tracks,
    Set<String>? rooms,
    TimeRange? timeRange,
    DurationRange? durationRange,
    Set<int>? days,
  }) {
    return EventFilter(
      tracks: tracks ?? this.tracks,
      rooms: rooms ?? this.rooms,
      timeRange: timeRange ?? this.timeRange,
      durationRange: durationRange ?? this.durationRange,
      days: days ?? this.days,
    );
  }

  @override
  List<Object?> get props => [tracks, rooms, timeRange, durationRange, days];
}

class SavedFilter extends Equatable {
  final String id;
  final String name;
  final EventFilter filter;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const SavedFilter({
    required this.id,
    required this.name,
    required this.filter,
    required this.createdAt,
    this.lastUsed,
  });

  @override
  List<Object?> get props => [id, name, filter, createdAt, lastUsed];
}
