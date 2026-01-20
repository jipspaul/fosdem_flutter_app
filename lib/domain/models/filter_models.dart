import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum FilterChipType {
  track,
  room,
  eventType,
  day,
}

class EventFilter extends Equatable {
  final String? searchQuery;
  final Set<String> tracks;
  final Set<String> rooms;
  final Set<String> eventTypes;
  final Set<int> days;
  final DateTimeRange? dateRange;
  final RangeValues? durationRange;
  final bool favoritesOnly;

  const EventFilter({
    this.searchQuery,
    this.tracks = const {},
    this.rooms = const {},
    this.eventTypes = const {},
    this.days = const {},
    this.dateRange,
    this.durationRange,
    this.favoritesOnly = false,
  });

  bool get isActive =>
      searchQuery != null ||
      tracks.isNotEmpty ||
      rooms.isNotEmpty ||
      eventTypes.isNotEmpty ||
      days.isNotEmpty ||
      dateRange != null ||
      durationRange != null ||
      favoritesOnly;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (tracks.isNotEmpty) count++;
    if (rooms.isNotEmpty) count++;
    if (eventTypes.isNotEmpty) count++;
    if (days.isNotEmpty) count++;
    if (dateRange != null) count++;
    if (durationRange != null) count++;
    if (favoritesOnly) count++;
    return count;
  }

  EventFilter copyWith({
    String? searchQuery,
    Set<String>? tracks,
    Set<String>? rooms,
    Set<String>? eventTypes,
    Set<int>? days,
    DateTimeRange? dateRange,
    RangeValues? durationRange,
    bool? favoritesOnly,
  }) {
    return EventFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      tracks: tracks ?? this.tracks,
      rooms: rooms ?? this.rooms,
      eventTypes: eventTypes ?? this.eventTypes,
      days: days ?? this.days,
      dateRange: dateRange ?? this.dateRange,
      durationRange: durationRange ?? this.durationRange,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'tracks': tracks.toList(),
      'rooms': rooms.toList(),
      'eventTypes': eventTypes.toList(),
      'days': days.toList(),
      'dateRange': dateRange != null
          ? {
              'start': dateRange!.start.toIso8601String(),
              'end': dateRange!.end.toIso8601String(),
            }
          : null,
      'durationRange': durationRange != null
          ? {
              'start': durationRange!.start,
              'end': durationRange!.end,
            }
          : null,
      'favoritesOnly': favoritesOnly,
    };
  }

  factory EventFilter.fromJson(Map<String, dynamic> json) {
    return EventFilter(
      searchQuery: json['searchQuery'] as String?,
      tracks: (json['tracks'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      rooms: (json['rooms'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      eventTypes: (json['eventTypes'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      days: (json['days'] as List<dynamic>?)?.cast<int>().toSet() ?? {},
      dateRange: json['dateRange'] != null
          ? DateTimeRange(
              start: DateTime.parse(json['dateRange']['start']),
              end: DateTime.parse(json['dateRange']['end']),
            )
          : null,
      durationRange: json['durationRange'] != null
          ? RangeValues(
              json['durationRange']['start'] as double,
              json['durationRange']['end'] as double,
            )
          : null,
      favoritesOnly: json['favoritesOnly'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        tracks,
        rooms,
        eventTypes,
        days,
        dateRange,
        durationRange,
        favoritesOnly,
      ];
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

  SavedFilter copyWith({
    String? id,
    String? name,
    EventFilter? filter,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return SavedFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      filter: filter ?? this.filter,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filter': filter.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  factory SavedFilter.fromJson(Map<String, dynamic> json) {
    return SavedFilter(
      id: json['id'] as String,
      name: json['name'] as String,
      filter: EventFilter.fromJson(json['filter'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, filter, createdAt, lastUsed];
}

class FilterSuggestion extends Equatable {
  final String id;
  final String displayText;
  final FilterChipType type;
  final String value;
  final int matchCount;

  const FilterSuggestion({
    required this.id,
    required this.displayText,
    required this.type,
    required this.value,
    required this.matchCount,
  });

  @override
  List<Object?> get props => [id, displayText, type, value, matchCount];
}
