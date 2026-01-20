import 'package:equatable/equatable.dart';

abstract class EventDiscoveryEvent extends Equatable {
  const EventDiscoveryEvent();

  @override
  List<Object?> get props => [];
}

class LoadNextEvent extends EventDiscoveryEvent {}

class SwipeLeft extends EventDiscoveryEvent {
  final String eventId;

  const SwipeLeft(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class SwipeRight extends EventDiscoveryEvent {
  final String eventId;

  const SwipeRight(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class SkipEvent extends EventDiscoveryEvent {
  final String eventId;

  const SkipEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class ResetDiscovery extends EventDiscoveryEvent {}
