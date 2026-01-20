import 'package:equatable/equatable.dart';
import '../../../../domain/entities/event_domain.dart';

abstract class EventDiscoveryState extends Equatable {
  const EventDiscoveryState();

  @override
  List<Object?> get props => [];
}

class EventDiscoveryInitial extends EventDiscoveryState {}

class EventDiscoveryLoading extends EventDiscoveryState {}

class EventDiscoveryLoaded extends EventDiscoveryState {
  final EventDomain currentEvent;
  final int remainingCount;
  final int totalSeen;

  const EventDiscoveryLoaded({
    required this.currentEvent,
    required this.remainingCount,
    required this.totalSeen,
  });

  @override
  List<Object?> get props => [currentEvent, remainingCount, totalSeen];
}

class EventDiscoveryEmpty extends EventDiscoveryState {
  final String message;

  const EventDiscoveryEmpty(this.message);

  @override
  List<Object?> get props => [message];
}

class EventDiscoveryError extends EventDiscoveryState {
  final String message;

  const EventDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}
