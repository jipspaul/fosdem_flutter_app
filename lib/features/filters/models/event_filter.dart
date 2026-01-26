import 'package:equatable/equatable.dart';
import 'filter_criterion.dart';

enum FilterType {
  text,
  track,
  room,
  dateRange,
  timeRange,
  duration,
  favorites,
  dayTimeBlock,
  nextHours,
}

class EventFilter extends Equatable {
  final FilterType type;
  final FilterCriterion criterion;
  final bool enabled;

  const EventFilter({
    required this.type,
    required this.criterion,
    this.enabled = true,
  });

  EventFilter copyWith({
    FilterType? type,
    FilterCriterion? criterion,
    bool? enabled,
  }) {
    return EventFilter(
      type: type ?? this.type,
      criterion: criterion ?? this.criterion,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'criterion': criterion.toJson(),
    'enabled': enabled,
  };

  factory EventFilter.fromJson(Map<String, dynamic> json) {
    final type = FilterType.values.byName(json['type'] as String);
    final criterionJson = json['criterion'] as Map<String, dynamic>;
    final criterionType = criterionJson['type'] as String;
    
    FilterCriterion criterion;
    switch (criterionType) {
      case 'text':
        criterion = TextCriterion.fromJson(criterionJson);
        break;
      case 'track':
        criterion = TrackCriterion.fromJson(criterionJson);
        break;
      case 'room':
        criterion = RoomCriterion.fromJson(criterionJson);
        break;
      case 'dateRange':
        criterion = DateRangeCriterion.fromJson(criterionJson);
        break;
      case 'timeRange':
        criterion = TimeRangeCriterion.fromJson(criterionJson);
        break;
      case 'duration':
        criterion = DurationCriterion.fromJson(criterionJson);
        break;
      case 'favorites':
        criterion = FavoritesCriterion.fromJson(criterionJson);
        break;
      case 'dayTimeBlock':
        criterion = DayTimeBlockCriterion.fromJson(criterionJson);
        break;
      case 'nextHours':
        criterion = NextHoursCriterion.fromJson(criterionJson);
        break;
      default:
        throw Exception('Unknown criterion type: $criterionType');
    }
    
    return EventFilter(
      type: type,
      criterion: criterion,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [type, criterion, enabled];
}
