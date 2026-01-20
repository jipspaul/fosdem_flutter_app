import 'package:latlong2/latlong.dart';

enum JourneyStatus {
  wishlist,
  planned,
  attending,
  attended,
  missed,
  cancelled,
}

enum TransitionDifficulty {
  easy,
  moderate,
  hard,
  impossible,
}

enum ConflictType {
  timeOverlap,
  impossibleTransition,
  priorityConflict,
  tooManyEvents,
  backToBackNoBreak,
}

enum ConflictSeverity {
  critical,
  high,
  medium,
  low,
  info,
}

enum ResolutionType {
  removeLowestPriority,
  swapWithAlternative,
  adjustTiming,
  moveToWishlist,
  addBufferTime,
  suggestRecording,
}

class JourneyItem {
  final String id;
  final int eventId;
  final String eventTitle;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String room;
  final String building;
  final String track;
  final LatLng location;
  final JourneyStatus status;
  final int priority;
  final DateTime addedAt;
  final String? notes;
  final List<String> tags;

  const JourneyItem({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.room,
    required this.building,
    required this.track,
    required this.location,
    required this.status,
    required this.priority,
    required this.addedAt,
    this.notes,
    this.tags = const [],
  });

  JourneyItem copyWith({
    String? id,
    int? eventId,
    String? eventTitle,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? room,
    String? building,
    String? track,
    LatLng? location,
    JourneyStatus? status,
    int? priority,
    DateTime? addedAt,
    String? notes,
    List<String>? tags,
  }) {
    return JourneyItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      room: room ?? this.room,
      building: building ?? this.building,
      track: track ?? this.track,
      location: location ?? this.location,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      addedAt: addedAt ?? this.addedAt,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}

class TransitionInfo {
  final JourneyItem fromEvent;
  final JourneyItem toEvent;
  final Duration walkingTime;
  final double distance;
  final bool isFeasible;
  final Duration bufferTime;
  final TransitionDifficulty difficulty;
  final String? warning;
  final List<String> route;

  const TransitionInfo({
    required this.fromEvent,
    required this.toEvent,
    required this.walkingTime,
    required this.distance,
    required this.isFeasible,
    required this.bufferTime,
    required this.difficulty,
    this.warning,
    this.route = const [],
  });
}

class Conflict {
  final String id;
  final ConflictType type;
  final List<JourneyItem> affectedEvents;
  final ConflictSeverity severity;
  final String description;
  final List<ConflictResolution> suggestedResolutions;

  const Conflict({
    required this.id,
    required this.type,
    required this.affectedEvents,
    required this.severity,
    required this.description,
    this.suggestedResolutions = const [],
  });
}

class ConflictResolution {
  final String id;
  final ResolutionType type;
  final String description;
  final List<int> eventsToAdd;
  final List<String> eventsToRemove;
  final List<String> eventsToDowngrade;
  final double scoreImprovement;
  final Map<String, dynamic> metadata;

  const ConflictResolution({
    required this.id,
    required this.type,
    required this.description,
    this.eventsToAdd = const [],
    this.eventsToRemove = const [],
    this.eventsToDowngrade = const [],
    this.scoreImprovement = 0.0,
    this.metadata = const {},
  });
}

class JourneyStats {
  final int totalEvents;
  final int wishlistCount;
  final int plannedCount;
  final int attendedCount;
  final int conflictCount;
  final Duration totalWalkingTime;
  final double totalDistance;
  final Map<String, int> eventsByTrack;
  final Map<String, int> eventsByBuilding;
  final int longestStreak;
  final double scheduleUtilization;

  const JourneyStats({
    required this.totalEvents,
    required this.wishlistCount,
    required this.plannedCount,
    required this.attendedCount,
    required this.conflictCount,
    required this.totalWalkingTime,
    required this.totalDistance,
    required this.eventsByTrack,
    required this.eventsByBuilding,
    required this.longestStreak,
    required this.scheduleUtilization,
  });
}

class JourneyPreferences {
  final Duration minimumBreakTime;
  final double walkingSpeedMps;
  final int maxEventsPerDay;
  final bool allowBackToBack;
  final bool autoOptimize;
  final List<String> priorityTags;
  final bool notifyBeforeEvent;

  const JourneyPreferences({
    this.minimumBreakTime = const Duration(minutes: 15),
    this.walkingSpeedMps = 1.4,
    this.maxEventsPerDay = 10,
    this.allowBackToBack = false,
    this.autoOptimize = true,
    this.priorityTags = const [],
    this.notifyBeforeEvent = true,
  });

  JourneyPreferences copyWith({
    Duration? minimumBreakTime,
    double? walkingSpeedMps,
    int? maxEventsPerDay,
    bool? allowBackToBack,
    bool? autoOptimize,
    List<String>? priorityTags,
    bool? notifyBeforeEvent,
  }) {
    return JourneyPreferences(
      minimumBreakTime: minimumBreakTime ?? this.minimumBreakTime,
      walkingSpeedMps: walkingSpeedMps ?? this.walkingSpeedMps,
      maxEventsPerDay: maxEventsPerDay ?? this.maxEventsPerDay,
      allowBackToBack: allowBackToBack ?? this.allowBackToBack,
      autoOptimize: autoOptimize ?? this.autoOptimize,
      priorityTags: priorityTags ?? this.priorityTags,
      notifyBeforeEvent: notifyBeforeEvent ?? this.notifyBeforeEvent,
    );
  }
}

class JourneyDay {
  final DateTime date;
  final List<JourneyItem> events;
  final List<Conflict> conflicts;
  final JourneyDayStats stats;

  const JourneyDay({
    required this.date,
    required this.events,
    required this.conflicts,
    required this.stats,
  });
}

class JourneyDayStats {
  final int eventCount;
  final Duration totalEventTime;
  final Duration totalWalkingTime;
  final double totalDistance;
  final int buildingChanges;
  final Duration longestBreak;
  final ConflictSeverity? maxConflictSeverity;

  const JourneyDayStats({
    required this.eventCount,
    required this.totalEventTime,
    required this.totalWalkingTime,
    required this.totalDistance,
    required this.buildingChanges,
    required this.longestBreak,
    this.maxConflictSeverity,
  });
}
