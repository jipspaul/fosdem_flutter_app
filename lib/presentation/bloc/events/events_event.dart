import '../../bloc/base/base_event.dart';

abstract class EventsEvent extends BaseEvent {
  const EventsEvent();
}

class LoadEvents extends EventsEvent {
  const LoadEvents();
}

class RefreshEvents extends EventsEvent {
  const RefreshEvents();
}

class SearchEvents extends EventsEvent {
  final String query;
  
  const SearchEvents(this.query);
  
  @override
  List<Object?> get props => [query];
}

class FilterEventsByTrack extends EventsEvent {
  final String trackId;
  
  const FilterEventsByTrack(this.trackId);
  
  @override
  List<Object?> get props => [trackId];
}

class FilterEventsByDate extends EventsEvent {
  final DateTime date;
  
  const FilterEventsByDate(this.date);
  
  @override
  List<Object?> get props => [date];
}

class ClearFilters extends EventsEvent {
  const ClearFilters();
}
