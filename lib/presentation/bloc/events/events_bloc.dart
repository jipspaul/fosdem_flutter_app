import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../../data/repositories/event_repository.dart';
import '../../bloc/base/base_bloc.dart';
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends BaseBloc<EventsEvent, EventsState> {
  final EventRepository _repository;

  EventsBloc(this._repository) : super(const EventsInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<RefreshEvents>(_onRefreshEvents);
    on<SearchEvents>(
      _onSearchEvents,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .asyncExpand(mapper),
    );
    on<FilterEventsByTrack>(_onFilterByTrack);
    on<FilterEventsByDate>(_onFilterByDate);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoadEvents(
    LoadEvents event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(const EventsLoading());
      final events = await _repository.getEvents();
      emit(EventsLoaded(events: events));
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onRefreshEvents(
    RefreshEvents event,
    Emitter<EventsState> emit,
  ) async {
    try {
      await _repository.syncEvents();
      final events = await _repository.getEvents();
      emit(EventsLoaded(events: events));
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onSearchEvents(
    SearchEvents event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(const EventsLoading());
      final events = await _repository.searchEvents(event.query);
      emit(EventsLoaded(events: events, searchQuery: event.query));
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onFilterByTrack(
    FilterEventsByTrack event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(const EventsLoading());
      final events = await _repository.getEventsByTrack(event.trackId);
      emit(EventsLoaded(events: events, activeFilter: 'track:${event.trackId}'));
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onFilterByDate(
    FilterEventsByDate event,
    Emitter<EventsState> emit,
  ) async {
    try {
      emit(const EventsLoading());
      final events = await _repository.getEventsByDate(event.date);
      emit(EventsLoaded(events: events, activeFilter: 'date:${event.date}'));
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<EventsState> emit,
  ) async {
    add(const LoadEvents());
  }
}
