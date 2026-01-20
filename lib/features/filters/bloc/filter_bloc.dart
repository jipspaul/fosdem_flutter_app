import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/event_filter.dart';
import '../models/filter_criterion.dart';
import '../services/filter_persistence_service.dart';
import '../../../data/datasources/local/database.dart';

// Events
abstract class FilterEvent extends Equatable {
  const FilterEvent();
  
  @override
  List<Object?> get props => [];
}

class AddFilter extends FilterEvent {
  final EventFilter filter;
  
  const AddFilter(this.filter);
  
  @override
  List<Object?> get props => [filter];
}

class RemoveFilter extends FilterEvent {
  final FilterType type;
  
  const RemoveFilter(this.type);
  
  @override
  List<Object?> get props => [type];
}

class ClearFilters extends FilterEvent {}

class LoadSavedFilters extends FilterEvent {}

class SaveFilters extends FilterEvent {}

// States
abstract class FilterState extends Equatable {
  const FilterState();
  
  @override
  List<Object?> get props => [];
}

class FilterInitial extends FilterState {}

class FilterApplied extends FilterState {
  final List<EventFilter> filters;
  
  const FilterApplied(this.filters);
  
  bool get hasActiveFilters => filters.isNotEmpty;
  
  List<dynamic> applyFilters(List<dynamic> events) {
    if (filters.isEmpty) return events;
    
    return events.where((event) {
      for (final filter in filters) {
        if (filter.enabled && !filter.criterion.matches(event)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
  
  @override
  List<Object?> get props => [filters];
}

// BLoC
class FilterBloc extends Bloc<FilterEvent, FilterState> {
  final FilterPersistenceService persistenceService;
  final AppDatabase database;
  
  FilterBloc({
    required this.persistenceService,
    required this.database,
  }) : super(FilterInitial()) {
    on<AddFilter>(_onAddFilter);
    on<RemoveFilter>(_onRemoveFilter);
    on<ClearFilters>(_onClearFilters);
    on<LoadSavedFilters>(_onLoadSavedFilters);
    on<SaveFilters>(_onSaveFilters);
  }
  
  void _onAddFilter(AddFilter event, Emitter<FilterState> emit) {
    final currentFilters = state is FilterApplied 
        ? List<EventFilter>.from((state as FilterApplied).filters)
        : <EventFilter>[];
    
    // Remove existing filter of same type
    currentFilters.removeWhere((f) => f.type == event.filter.type);
    
    // Add new filter
    currentFilters.add(event.filter);
    
    emit(FilterApplied(currentFilters));
    add(SaveFilters());
  }
  
  void _onRemoveFilter(RemoveFilter event, Emitter<FilterState> emit) {
    final currentFilters = state is FilterApplied 
        ? List<EventFilter>.from((state as FilterApplied).filters)
        : <EventFilter>[];
    
    currentFilters.removeWhere((f) => f.type == event.type);
    
    emit(FilterApplied(currentFilters));
    add(SaveFilters());
  }
  
  void _onClearFilters(ClearFilters event, Emitter<FilterState> emit) {
    emit(const FilterApplied([]));
    add(SaveFilters());
  }
  
  Future<void> _onLoadSavedFilters(LoadSavedFilters event, Emitter<FilterState> emit) async {
    final filters = await persistenceService.loadFilters();
    emit(FilterApplied(filters));
  }
  
  Future<void> _onSaveFilters(SaveFilters event, Emitter<FilterState> emit) async {
    if (state is FilterApplied) {
      await persistenceService.saveFilters((state as FilterApplied).filters);
    }
  }
}
