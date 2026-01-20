import 'package:equatable/equatable.dart';

/// Enum for filter types
enum FilterType {
  track,
  room,
  date,
  timeRange,
  duration,
  speaker,
  hasVideo,
  hasAttachments,
  searchText,
  status, // now, upcoming, past
  day, // Saturday, Sunday
}

/// Enum for event status
enum EventStatus {
  all,
  now,
  upcoming,
  past,
}

/// Time range filter
class TimeRange extends Equatable {
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int endHour; // 0-23
  final int endMinute; // 0-59

  const TimeRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  bool contains(DateTime time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  @override
  List<Object?> get props => [startHour, startMinute, endHour, endMinute];

  @override
  String toString() {
    return '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }
}

/// Duration range filter (in minutes)
class DurationRange extends Equatable {
  final int minDuration;
  final int maxDuration;

  const DurationRange({
    required this.minDuration,
    required this.maxDuration,
  });

  bool contains(int duration) {
    return duration >= minDuration && duration <= maxDuration;
  }

  @override
  List<Object?> get props => [minDuration, maxDuration];

  @override
  String toString() {
    return '${minDuration}min - ${maxDuration}min';
  }
}

/// Main filter criteria class
class FilterCriteria extends Equatable {
  final Set<String> selectedTracks;
  final Set<String> selectedRooms;
  final Set<DateTime> selectedDates;
  final TimeRange? timeRange;
  final DurationRange? durationRange;
  final Set<String> selectedSpeakers;
  final bool? hasVideo;
  final bool? hasAttachments;
  final String? searchText;
  final EventStatus status;
  final Set<int> selectedDays; // 1 = Saturday, 2 = Sunday

  const FilterCriteria({
    this.selectedTracks = const {},
    this.selectedRooms = const {},
    this.selectedDates = const {},
    this.timeRange,
    this.durationRange,
    this.selectedSpeakers = const {},
    this.hasVideo,
    this.hasAttachments,
    this.searchText,
    this.status = EventStatus.all,
    this.selectedDays = const {},
  });

  bool get hasActiveFilters {
    return selectedTracks.isNotEmpty ||
        selectedRooms.isNotEmpty ||
        selectedDates.isNotEmpty ||
        timeRange != null ||
        durationRange != null ||
        selectedSpeakers.isNotEmpty ||
        hasVideo != null ||
        hasAttachments != null ||
        (searchText?.isNotEmpty ?? false) ||
        status != EventStatus.all ||
        selectedDays.isNotEmpty;
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedTracks.isNotEmpty) count++;
    if (selectedRooms.isNotEmpty) count++;
    if (selectedDates.isNotEmpty) count++;
    if (timeRange != null) count++;
    if (durationRange != null) count++;
    if (selectedSpeakers.isNotEmpty) count++;
    if (hasVideo != null) count++;
    if (hasAttachments != null) count++;
    if (searchText?.isNotEmpty ?? false) count++;
    if (status != EventStatus.all) count++;
    if (selectedDays.isNotEmpty) count++;
    return count;
  }

  FilterCriteria copyWith({
    Set<String>? selectedTracks,
    Set<String>? selectedRooms,
    Set<DateTime>? selectedDates,
    TimeRange? timeRange,
    bool clearTimeRange = false,
    DurationRange? durationRange,
    bool clearDurationRange = false,
    Set<String>? selectedSpeakers,
    bool? hasVideo,
    bool clearHasVideo = false,
    bool? hasAttachments,
    bool clearHasAttachments = false,
    String? searchText,
    bool clearSearchText = false,
    EventStatus? status,
    Set<int>? selectedDays,
  }) {
    return FilterCriteria(
      selectedTracks: selectedTracks ?? this.selectedTracks,
      selectedRooms: selectedRooms ?? this.selectedRooms,
      selectedDates: selectedDates ?? this.selectedDates,
      timeRange: clearTimeRange ? null : (timeRange ?? this.timeRange),
      durationRange:
          clearDurationRange ? null : (durationRange ?? this.durationRange),
      selectedSpeakers: selectedSpeakers ?? this.selectedSpeakers,
      hasVideo: clearHasVideo ? null : (hasVideo ?? this.hasVideo),
      hasAttachments:
          clearHasAttachments ? null : (hasAttachments ?? this.hasAttachments),
      searchText: clearSearchText ? null : (searchText ?? this.searchText),
      status: status ?? this.status,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }

  FilterCriteria clear() {
    return const FilterCriteria();
  }

  @override
  List<Object?> get props => [
        selectedTracks,
        selectedRooms,
        selectedDates,
        timeRange,
        durationRange,
        selectedSpeakers,
        hasVideo,
        hasAttachments,
        searchText,
        status,
        selectedDays,
      ];
}

/// Filter preset for quick access
class FilterPreset extends Equatable {
  final String id;
  final String name;
  final String? description;
  final FilterCriteria criteria;
  final DateTime createdAt;

  const FilterPreset({
    required this.id,
    required this.name,
    this.description,
    required this.criteria,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, description, criteria, createdAt];
}
