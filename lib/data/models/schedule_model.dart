import 'package:equatable/equatable.dart';
import 'event_model.dart';
import 'track_model.dart';

class DayModel extends Equatable {
  final DateTime date;
  final int dayNumber;
  final List<EventModel> events;

  const DayModel({
    required this.date,
    required this.dayNumber,
    this.events = const [],
  });

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      date: DateTime.parse(json['date'] as String),
      dayNumber: json['day_number'] as int? ?? json['dayNumber'] as int? ?? 1,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => EventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayNumber': dayNumber,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  String get displayDate {
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1];
    return '$weekday, ${date.day}/${date.month}/${date.year}';
  }

  String get shortDisplayDate {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    return '$weekday ${date.day}/${date.month}';
  }

  List<EventModel> getEventsByTrack(String track) {
    return events.where((e) => e.track == track).toList();
  }

  List<EventModel> getEventsByRoom(String room) {
    return events.where((e) => e.room == room).toList();
  }

  List<EventModel> getEventsInTimeRange(DateTime start, DateTime end) {
    return events.where((e) => 
      e.start.isAfter(start) && e.start.isBefore(end)
    ).toList();
  }

  DayModel copyWith({
    DateTime? date,
    int? dayNumber,
    List<EventModel>? events,
  }) {
    return DayModel(
      date: date ?? this.date,
      dayNumber: dayNumber ?? this.dayNumber,
      events: events ?? this.events,
    );
  }

  @override
  List<Object?> get props => [date, dayNumber, events];
}

class ScheduleModel extends Equatable {
  final List<DayModel> days;
  final List<TrackModel> tracks;

  const ScheduleModel({
    this.days = const [],
    this.tracks = const [],
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      days: (json['days'] as List<dynamic>?)
              ?.map((d) => DayModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((t) => TrackModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days.map((d) => d.toJson()).toList(),
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }

  List<EventModel> get allEvents {
    return days.expand((day) => day.events).toList();
  }

  List<String> get allRooms {
    final rooms = allEvents.map((e) => e.room).toSet().toList();
    rooms.sort();
    return rooms;
  }

  List<String> get allTrackNames {
    return tracks.map((t) => t.name).toList();
  }

  DayModel? getDayByDate(DateTime date) {
    try {
      return days.firstWhere((day) => 
        day.date.year == date.year &&
        day.date.month == date.month &&
        day.date.day == date.day
      );
    } catch (e) {
      return null;
    }
  }

  DayModel? getDayByNumber(int dayNumber) {
    try {
      return days.firstWhere((day) => day.dayNumber == dayNumber);
    } catch (e) {
      return null;
    }
  }

  List<EventModel> getEventsByTrack(String track) {
    return allEvents.where((e) => e.track == track).toList();
  }

  List<EventModel> getEventsByRoom(String room) {
    return allEvents.where((e) => e.room == room).toList();
  }

  List<EventModel> searchEvents(String query) {
    final lowerQuery = query.toLowerCase();
    return allEvents.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
          (event.subtitle?.toLowerCase().contains(lowerQuery) ?? false) ||
          (event.abstract?.toLowerCase().contains(lowerQuery) ?? false) ||
          event.track.toLowerCase().contains(lowerQuery) ||
          event.room.toLowerCase().contains(lowerQuery) ||
          event.people.any((p) => p.name.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  EventModel? getEventById(int id) {
    try {
      return allEvents.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  DateTime? get startDate => days.isEmpty ? null : days.first.date;

  DateTime? get endDate => days.isEmpty ? null : days.last.date;

  int get totalEvents => allEvents.length;

  ScheduleModel copyWith({
    List<DayModel>? days,
    List<TrackModel>? tracks,
  }) {
    return ScheduleModel(
      days: days ?? this.days,
      tracks: tracks ?? this.tracks,
    );
  }

  @override
  List<Object?> get props => [days, tracks];
}
