import 'package:equatable/equatable.dart';
import 'event.dart';
import 'track.dart';

/// Domain entity representing a complete FOSDEM schedule
class Schedule extends Equatable {
  final List<Event> events;
  final List<Track> tracks;
  final DateTime lastUpdated;
  final int year;

  const Schedule({
    required this.events,
    required this.tracks,
    required this.lastUpdated,
    required this.year,
  });

  @override
  List<Object?> get props => [events, tracks, lastUpdated, year];
}
