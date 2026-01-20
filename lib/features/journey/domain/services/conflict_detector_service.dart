import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/journey_models.dart';

class ConflictDetectorService {
  final JourneyPreferences preferences;

  ConflictDetectorService(this.preferences);

  List<Conflict> detectConflicts(List<JourneyItem> journeyItems) {
    final conflicts = <Conflict>[];
    final plannedItems = journeyItems
        .where((item) => item.status == JourneyStatus.planned)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (plannedItems.isEmpty) return conflicts;

    for (int i = 0; i < plannedItems.length - 1; i++) {
      final current = plannedItems[i];
      final next = plannedItems[i + 1];

      // 1. Time Overlap Check
      final overlapConflict = _checkTimeOverlap(current, next);
      if (overlapConflict != null) {
        conflicts.add(overlapConflict);
        continue;
      }

      // 2. Transition Feasibility Check
      final transitionConflict = _checkTransitionFeasibility(current, next);
      if (transitionConflict != null) {
        conflicts.add(transitionConflict);
      }

      // 3. Back-to-Back Without Break
      if (!preferences.allowBackToBack) {
        final breakConflict = _checkBreakTime(current, next);
        if (breakConflict != null) {
          conflicts.add(breakConflict);
        }
      }
    }

    // 4. Overload Detection
    conflicts.addAll(_checkScheduleOverload(plannedItems));

    return conflicts;
  }

  Conflict? _checkTimeOverlap(JourneyItem a, JourneyItem b) {
    if (a.endTime.isAfter(b.startTime)) {
      return Conflict(
        id: '${a.id}_${b.id}_overlap',
        type: ConflictType.timeOverlap,
        affectedEvents: [a, b],
        severity: ConflictSeverity.critical,
        description: '${a.eventTitle} and ${b.eventTitle} overlap',
        suggestedResolutions: [
          ConflictResolution(
            id: 'remove_lower_priority',
            type: ResolutionType.removeLowestPriority,
            description: a.priority > b.priority
                ? 'Remove "${a.eventTitle}" (Priority ${a.priority})'
                : 'Remove "${b.eventTitle}" (Priority ${b.priority})',
            eventsToRemove: [a.priority > b.priority ? a.id : b.id],
            scoreImprovement: 100,
          ),
        ],
      );
    }
    return null;
  }

  Conflict? _checkTransitionFeasibility(JourneyItem from, JourneyItem to) {
    // If events are in the same room, no transition needed
    if (from.room == to.room) {
      return null;
    }

    final transition = calculateTransition(from, to);

    if (!transition.isFeasible) {
      final severity = transition.bufferTime.inMinutes < 0
          ? ConflictSeverity.critical
          : transition.bufferTime.inMinutes < 2
              ? ConflictSeverity.high
              : ConflictSeverity.medium;

      return Conflict(
        id: '${from.id}_${to.id}_transition',
        type: ConflictType.impossibleTransition,
        affectedEvents: [from, to],
        severity: severity,
        description: 'Only ${transition.bufferTime.inMinutes} min to walk '
            '${transition.distance.toInt()}m from ${from.building} '
            'to ${to.building}',
        suggestedResolutions: [
          ConflictResolution(
            id: 'move_to_wishlist',
            type: ResolutionType.moveToWishlist,
            description: from.priority > to.priority
                ? 'Move "${from.eventTitle}" to wishlist'
                : 'Move "${to.eventTitle}" to wishlist',
            eventsToDowngrade: [from.priority > to.priority ? from.id : to.id],
            scoreImprovement: 50,
          ),
        ],
      );
    } else if (transition.bufferTime.inMinutes < 5) {
      return Conflict(
        id: '${from.id}_${to.id}_tight',
        type: ConflictType.impossibleTransition,
        affectedEvents: [from, to],
        severity: ConflictSeverity.low,
        description: 'Tight schedule: Only ${transition.bufferTime.inMinutes} min buffer',
      );
    }

    return null;
  }

  Conflict? _checkBreakTime(JourneyItem from, JourneyItem to) {
    // If events are in the same room, no break needed for transition
    if (from.room == to.room) {
      return null;
    }

    final gap = to.startTime.difference(from.endTime);

    if (gap < preferences.minimumBreakTime) {
      return Conflict(
        id: '${from.id}_${to.id}_nobreak',
        type: ConflictType.backToBackNoBreak,
        affectedEvents: [from, to],
        severity: ConflictSeverity.info,
        description: 'No break between events (${gap.inMinutes} min gap)',
      );
    }

    return null;
  }

  List<Conflict> _checkScheduleOverload(List<JourneyItem> items) {
    final conflicts = <Conflict>[];

    // Group by day
    final eventsByDay = <DateTime, List<JourneyItem>>{};
    for (final item in items) {
      final day = DateTime(
        item.startTime.year,
        item.startTime.month,
        item.startTime.day,
      );
      eventsByDay.putIfAbsent(day, () => []).add(item);
    }

    // Check each day
    for (final entry in eventsByDay.entries) {
      if (entry.value.length > preferences.maxEventsPerDay) {
        conflicts.add(Conflict(
          id: 'overload_${entry.key.toIso8601String()}',
          type: ConflictType.tooManyEvents,
          affectedEvents: entry.value,
          severity: ConflictSeverity.medium,
          description: '${entry.value.length} events scheduled '
              '(max: ${preferences.maxEventsPerDay})',
        ));
      }
    }

    return conflicts;
  }

  TransitionInfo calculateTransition(JourneyItem from, JourneyItem to) {
    // Calculate distance using haversine formula
    final distance = _calculateDistance(from.location, to.location);

    // Calculate walking time: distance / speed
    final walkingSeconds = (distance / preferences.walkingSpeedMps).ceil();
    final walkingTime = Duration(seconds: walkingSeconds);

    // Available time between events
    final availableTime = to.startTime.difference(from.endTime);
    final bufferTime = availableTime - walkingTime;

    final isFeasible = bufferTime >= Duration.zero;

    final difficulty = walkingTime.inMinutes < 2
        ? TransitionDifficulty.easy
        : walkingTime.inMinutes < 5
            ? TransitionDifficulty.moderate
            : walkingTime.inMinutes < 8
                ? TransitionDifficulty.hard
                : TransitionDifficulty.impossible;

    String? warning;
    if (!isFeasible) {
      warning = 'Need ${(walkingTime - availableTime).inMinutes.abs()} more minutes';
    } else if (bufferTime.inMinutes < 5) {
      warning = 'Very tight schedule, no time for delays';
    }

    return TransitionInfo(
      fromEvent: from,
      toEvent: to,
      walkingTime: walkingTime,
      distance: distance,
      isFeasible: isFeasible,
      bufferTime: bufferTime,
      difficulty: difficulty,
      warning: warning,
      route: [from.building, to.building],
    );
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude)) *
            cos(_toRadians(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  JourneyStats calculateStats(List<JourneyItem> items) {
    final wishlistItems = items.where((i) => i.status == JourneyStatus.wishlist).toList();
    final plannedItems = items.where((i) => i.status == JourneyStatus.planned).toList();
    final attendedItems = items.where((i) => i.status == JourneyStatus.attended).toList();

    final conflicts = detectConflicts(items);

    // Calculate walking time and distance
    Duration totalWalkingTime = Duration.zero;
    double totalDistance = 0.0;

    plannedItems.sort((a, b) => a.startTime.compareTo(b.startTime));
    for (int i = 0; i < plannedItems.length - 1; i++) {
      final transition = calculateTransition(plannedItems[i], plannedItems[i + 1]);
      totalWalkingTime += transition.walkingTime;
      totalDistance += transition.distance;
    }

    // Events by track
    final eventsByTrack = <String, int>{};
    for (final item in items) {
      eventsByTrack[item.track] = (eventsByTrack[item.track] ?? 0) + 1;
    }

    // Events by building
    final eventsByBuilding = <String, int>{};
    for (final item in items) {
      eventsByBuilding[item.building] = (eventsByBuilding[item.building] ?? 0) + 1;
    }

    // Calculate schedule utilization
    double scheduleUtilization = 0.0;
    if (plannedItems.isNotEmpty) {
      final totalPlannedTime = plannedItems.fold<Duration>(
        Duration.zero,
        (sum, item) => sum + item.duration,
      );
      final firstEvent = plannedItems.first.startTime;
      final lastEvent = plannedItems.last.endTime;
      final totalAvailableTime = lastEvent.difference(firstEvent);
      scheduleUtilization = totalPlannedTime.inMinutes / totalAvailableTime.inMinutes;
    }

    return JourneyStats(
      totalEvents: items.length,
      wishlistCount: wishlistItems.length,
      plannedCount: plannedItems.length,
      attendedCount: attendedItems.length,
      conflictCount: conflicts.length,
      totalWalkingTime: totalWalkingTime,
      totalDistance: totalDistance,
      eventsByTrack: eventsByTrack,
      eventsByBuilding: eventsByBuilding,
      longestStreak: _calculateLongestStreak(plannedItems),
      scheduleUtilization: scheduleUtilization,
    );
  }

  int _calculateLongestStreak(List<JourneyItem> items) {
    if (items.isEmpty) return 0;

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < items.length; i++) {
      final gap = items[i].startTime.difference(items[i - 1].endTime);
      if (gap.inMinutes < 30) {
        currentStreak++;
        maxStreak = max(maxStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }
}
