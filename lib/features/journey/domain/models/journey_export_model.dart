import 'package:latlong2/latlong.dart';

import 'journey_models.dart';

/// Export/import model for journey YAML.
/// - planned = in journey (plans to attend)
/// - wishlist = in favorites but not planned (interested, not planning to visit)
class JourneyExportEvent {
  final int eventId;
  final String eventName;
  final String status; // "planned" | "wishlist"
  final String startTime; // ISO8601
  final String endTime; // ISO8601
  final String room;
  final String building;
  final String track;
  final int priority;
  final String? notes;

  const JourneyExportEvent({
    required this.eventId,
    required this.eventName,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.building,
    required this.track,
    required this.priority,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'status': status,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'building': building,
      'track': track,
      'priority': priority,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  factory JourneyExportEvent.fromJson(Map<dynamic, dynamic> json) {
    return JourneyExportEvent(
      eventId: _intFromJson(json['eventId']) ?? 0,
      eventName: json['eventName'] as String? ?? '',
      status: json['status'] as String? ?? 'wishlist',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      room: json['room'] as String? ?? '',
      building: json['building'] as String? ?? '',
      track: json['track'] as String? ?? '',
      priority: _intFromJson(json['priority']) ?? 3,
      notes: json['notes'] as String?,
    );
  }

  /// Converts to JourneyItem for display (e.g. on timeline). Uses [suffix] for unique id.
  JourneyItem toJourneyItem(String idSuffix) {
    final start = startTime.isNotEmpty ? DateTime.tryParse(startTime) : null;
    final end = endTime.isNotEmpty ? DateTime.tryParse(endTime) : null;
    final s = start ?? DateTime.now();
    final e = end ?? s.add(const Duration(minutes: 60));
    const defaultLocation = LatLng(50.8120, 4.3800);
    return JourneyItem(
      id: 'imported_${eventId}_$idSuffix',
      eventId: eventId,
      eventTitle: eventName,
      startTime: s,
      endTime: e,
      duration: e.difference(s),
      room: room,
      building: building,
      track: track,
      location: defaultLocation,
      status: JourneyStatus.planned,
      priority: priority,
      addedAt: DateTime.now(),
      notes: notes,
      tags: [],
    );
  }
}

int? _intFromJson(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class JourneyExportData {
  final String userName;
  final String? userPictureUrl;
  final List<JourneyExportEvent> events;

  const JourneyExportData({
    required this.userName,
    this.userPictureUrl,
    this.events = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      if (userPictureUrl != null && userPictureUrl!.isNotEmpty) 'userPictureUrl': userPictureUrl,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  factory JourneyExportData.fromJson(Map<dynamic, dynamic> json) {
    final eventsList = json['events'];
    final events = <JourneyExportEvent>[];
    if (eventsList is List) {
      for (final e in eventsList) {
        if (e is Map) {
          events.add(JourneyExportEvent.fromJson(Map<dynamic, dynamic>.from(e)));
        }
      }
    }
    return JourneyExportData(
      userName: json['userName'] as String? ?? 'User',
      userPictureUrl: json['userPictureUrl'] as String?,
      events: events,
    );
  }
}
