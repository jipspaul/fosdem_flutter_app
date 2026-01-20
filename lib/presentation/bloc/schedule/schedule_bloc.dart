import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/event_domain.dart';
import '../../../data/repositories/event_repository.dart';

// Events
abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadSchedule extends ScheduleEvent {
  const LoadSchedule();
}

class RefreshSchedule extends ScheduleEvent {
  const RefreshSchedule();
}

class FilterByTrack extends ScheduleEvent {
  final String? track;
  
  const FilterByTrack(this.track);
  
  @override
  List<Object?> get props => [track];
}

class SearchEvents extends ScheduleEvent {
  final String query;
  
  const SearchEvents(this.query);
  
  @override
  List<Object?> get props => [query];
}

// States
abstract class ScheduleState extends Equatable {
  const ScheduleState();
  
  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class ScheduleLoaded extends ScheduleState {
  final List<EventDomain> events;
  final String? selectedTrack;
  final String? searchQuery;
  
  const ScheduleLoaded({
    required this.events,
    this.selectedTrack,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [events, selectedTrack, searchQuery];
}

class ScheduleError extends ScheduleState {
  final String message;
  
  const ScheduleError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final EventRepository eventRepository;
  
  ScheduleBloc({required this.eventRepository}) : super(const ScheduleInitial()) {
    on<LoadSchedule>(_onLoadSchedule);
    on<RefreshSchedule>(_onRefreshSchedule);
    on<FilterByTrack>(_onFilterByTrack);
    on<SearchEvents>(_onSearchEvents);
  }
  
  Future<void> _onLoadSchedule(
    LoadSchedule event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    
    try {
      final events = await eventRepository.getEvents();
      emit(ScheduleLoaded(events: events));
    } catch (e) {
      emit(ScheduleError('Failed to load schedule: $e'));
    }
  }
  
  Future<void> _onRefreshSchedule(
    RefreshSchedule event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      await eventRepository.syncEvents();
      final events = await eventRepository.getEvents();
      emit(ScheduleLoaded(events: events));
    } catch (e) {
      emit(ScheduleError('Failed to refresh schedule: $e'));
    }
  }
  
  Future<void> _onFilterByTrack(
    FilterByTrack event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      final events = event.track == null
          ? await eventRepository.getEvents()
          : await eventRepository.getEventsByTrack(event.track!);
      emit(ScheduleLoaded(
        events: events,
        selectedTrack: event.track,
      ));
    } catch (e) {
      emit(ScheduleError('Failed to filter events: $e'));
    }
  }
  
  Future<void> _onSearchEvents(
    SearchEvents event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      final events = await eventRepository.searchEvents(event.query);
      emit(ScheduleLoaded(
        events: events,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(ScheduleError('Failed to search events: $e'));
    }
  }
}
