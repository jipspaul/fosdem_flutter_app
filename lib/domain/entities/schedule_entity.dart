import '../../../data/models/track_model.dart';
import 'event_domain.dart';

class ScheduleEntity {
  final int id;
  final String name;
  final int year;
  final List<EventDomain> events;
  final List<TrackModel> tracks;
  final DateTime lastUpdated;

  const ScheduleEntity({
    required this.id,
    required this.name,
    required this.year,
    required this.events,
    required this.tracks,
    required this.lastUpdated,
  });
}

