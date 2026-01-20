import 'package:equatable/equatable.dart';
import '../../../domain/entities/event_detail.dart';

abstract class EventDetailState extends Equatable {
  const EventDetailState();

  @override
  List<Object?> get props => [];
}

class EventDetailInitial extends EventDetailState {
  const EventDetailInitial();
}

class EventDetailLoading extends EventDetailState {
  const EventDetailLoading();
}

class EventDetailLoaded extends EventDetailState {
  final EventDetail eventDetail;

  const EventDetailLoaded(this.eventDetail);

  @override
  List<Object?> get props => [eventDetail];
}

class EventDetailError extends EventDetailState {
  final String message;

  const EventDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
