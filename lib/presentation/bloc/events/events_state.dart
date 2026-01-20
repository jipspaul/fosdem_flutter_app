import '../../../domain/entities/event_domain.dart';
import '../../bloc/base/base_state.dart';

abstract class EventsState extends BaseState {
  const EventsState();
}

class EventsInitial extends EventsState {
  const EventsInitial();
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsLoaded extends EventsState {
  final List<EventDomain> events;
  final String? activeFilter;
  final String? searchQuery;
  
  const EventsLoaded({
    required this.events,
    this.activeFilter,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [events, activeFilter, searchQuery];
}

class EventsError extends EventsState {
  final String message;
  
  const EventsError(this.message);
  
  @override
  List<Object?> get props => [message];
}
