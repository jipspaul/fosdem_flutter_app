import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/models/filter_models.dart';
import '../../../data/services/filter_persistence_service.dart';

// Events
abstract class FilterEvent extends Equatable {
  const FilterEvent();

  @override
  List<Object?> get props => [];
}

class LoadSavedFilters extends FilterEvent {}

class ApplyFilter extends FilterEvent {
  final EventFilter filter;

  const ApplyFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

class UpdateTextSearch extends FilterEvent {
  final String query;

  const UpdateTextSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class ToggleFilterChip extends FilterEvent {
  final FilterChipType type;
  final String value;

  const ToggleFilterChip(this.type, this.value);

  @override
  List<Object?> get props => [type, value];
}

class UpdateDateRange extends FilterEvent {
  final DateTimeRange? range;

  const UpdateDateRange(this.range);

  @override
  List<Object?> get props => [range];
}

class UpdateDurationRange extends FilterEvent {
  final RangeValues range;

  const UpdateDurationRange(this.range);

  @override
  List<Object?> get props => [range];
}

class SaveCurrentFilter extends FilterEvent {
  final String name;

  const SaveCurrentFilter(this.name);

  @override
  List<Object?> get props => [name];
}

class DeleteSavedFilter extends FilterEvent {
  final String id;

  const DeleteSavedFilter(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadSavedFilter extends FilterEvent {
  final String id;

  const LoadSavedFilter(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearAllFilters extends FilterEvent {}

class ToggleFavoritesOnly extends FilterEvent {}

// States
abstract class FilterState extends Equatable {
  final EventFilter currentFilter;
  final List<SavedFilter> savedFilters;
  final bool isLoading;

  const FilterState({
    required this.currentFilter,
    required this.savedFilters,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [currentFilter, savedFilters, isLoading];
}

class FilterInitial extends FilterState {
  const FilterInitial()
      : super(
          currentFilter: const EventFilter(),
          savedFilters: const [],
        );
}

class FilterLoaded extends FilterState {
  const FilterLoaded({
    required super.currentFilter,
    required super.savedFilters,
    super.isLoading,
  });

  FilterLoaded copyWith({
    EventFilter? currentFilter,
    List<SavedFilter>? savedFilters,
    bool? isLoading,
  }) {
    return FilterLoaded(
      currentFilter: currentFilter ?? this.currentFilter,
      savedFilters: savedFilters ?? this.savedFilters,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FilterError extends FilterState {
  final String message;

  const FilterError({
    required super.currentFilter,
    required super.savedFilters,
    required this.message,
  });

  @override
  List<Object?> get props => [currentFilter, savedFilters, message];
}

// BLoC
class FilterBloc extends Bloc<FilterEvent, FilterState> {
  final FilterPersistenceService _persistenceService;
  
  FilterBloc(this._persistenceService) : super(const FilterInitial()) {
    on<LoadSavedFilters>(_onLoadSavedFilters);
    on<ApplyFilter>(_onApplyFilter);
    on<UpdateTextSearch>(_onUpdateTextSearch);
    on<ToggleFilterChip>(_onToggleFilterChip);
    on<UpdateDateRange>(_onUpdateDateRange);
    on<UpdateDurationRange>(_onUpdateDurationRange);
    on<SaveCurrentFilter>(_onSaveCurrentFilter);
    on<DeleteSavedFilter>(_onDeleteSavedFilter);
    on<LoadSavedFilter>(_onLoadSavedFilter);
    on<ClearAllFilters>(_onClearAllFilters);
    on<ToggleFavoritesOnly>(_onToggleFavoritesOnly);
  }

  Future<void> _onLoadSavedFilters(
    LoadSavedFilters event,
    Emitter<FilterState> emit,
  ) async {
    try {
      // Load saved presets from database
      final presets = await _persistenceService.loadAllPresets();
      final savedFilters = presets.map((p) => SavedFilter(
        id: p.id.toString(),
        name: p.name,
        filter: p.filter,
        createdAt: p.createdAt,
      )).toList();
      
      // Load default filter if exists
      final defaultFilter = await _persistenceService.loadDefaultFilter();
      
      emit(FilterLoaded(
        currentFilter: defaultFilter ?? const EventFilter(),
        savedFilters: savedFilters,
      ));
    } catch (e) {
      emit(FilterError(
        currentFilter: state.currentFilter,
        savedFilters: state.savedFilters,
        message: 'Failed to load saved filters: $e',
      ));
    }
  }

  Future<void> _onApplyFilter(
    ApplyFilter event,
    Emitter<FilterState> emit,
  ) async {
    if (state is FilterLoaded) {
      emit((state as FilterLoaded).copyWith(
        currentFilter: event.filter,
      ));
    } else {
      emit(FilterLoaded(
        currentFilter: event.filter,
        savedFilters: state.savedFilters,
      ));
    }
    
    // Auto-save as default filter
    try {
      final presets = await _persistenceService.loadAllPresets();
      if (presets.isEmpty) {
        await _persistenceService.saveFilterPreset('Default', event.filter, isDefault: true);
      } else {
        final defaultPreset = presets.firstWhere((p) => p.isDefault, orElse: () => presets.first);
        await _persistenceService.updatePreset(defaultPreset.id, defaultPreset.name, event.filter);
      }
    } catch (e) {
      // Ignore persistence errors
    }
  }

  Future<void> _onUpdateTextSearch(
    UpdateTextSearch event,
    Emitter<FilterState> emit,
  ) async {
    final newFilter = state.currentFilter.copyWith(
      searchQuery: event.query.isEmpty ? null : event.query,
    );
    add(ApplyFilter(newFilter));
  }

  Future<void> _onToggleFilterChip(
    ToggleFilterChip event,
    Emitter<FilterState> emit,
  ) async {
    final current = state.currentFilter;
    EventFilter newFilter;

    switch (event.type) {
      case FilterChipType.track:
        final tracks = Set<String>.from(current.tracks);
        if (tracks.contains(event.value)) {
          tracks.remove(event.value);
        } else {
          tracks.add(event.value);
        }
        newFilter = current.copyWith(tracks: tracks);
        break;

      case FilterChipType.room:
        final rooms = Set<String>.from(current.rooms);
        if (rooms.contains(event.value)) {
          rooms.remove(event.value);
        } else {
          rooms.add(event.value);
        }
        newFilter = current.copyWith(rooms: rooms);
        break;

      case FilterChipType.eventType:
        final types = Set<String>.from(current.eventTypes);
        if (types.contains(event.value)) {
          types.remove(event.value);
        } else {
          types.add(event.value);
        }
        newFilter = current.copyWith(eventTypes: types);
        break;

      case FilterChipType.day:
        final days = Set<int>.from(current.days);
        final dayNum = int.parse(event.value);
        if (days.contains(dayNum)) {
          days.remove(dayNum);
        } else {
          days.add(dayNum);
        }
        newFilter = current.copyWith(days: days);
        break;
    }

    add(ApplyFilter(newFilter));
  }

  Future<void> _onUpdateDateRange(
    UpdateDateRange event,
    Emitter<FilterState> emit,
  ) async {
    final newFilter = state.currentFilter.copyWith(
      dateRange: event.range,
    );
    add(ApplyFilter(newFilter));
  }

  Future<void> _onUpdateDurationRange(
    UpdateDurationRange event,
    Emitter<FilterState> emit,
  ) async {
    final newFilter = state.currentFilter.copyWith(
      durationRange: event.range,
    );
    add(ApplyFilter(newFilter));
  }

  Future<void> _onSaveCurrentFilter(
    SaveCurrentFilter event,
    Emitter<FilterState> emit,
  ) async {
    try {
      final id = await _persistenceService.saveFilterPreset(event.name, state.currentFilter);
      
      final savedFilter = SavedFilter(
        id: id.toString(),
        name: event.name,
        filter: state.currentFilter,
        createdAt: DateTime.now(),
      );

      final updatedSavedFilters = [...state.savedFilters, savedFilter];
      
      if (state is FilterLoaded) {
        emit((state as FilterLoaded).copyWith(
          savedFilters: updatedSavedFilters,
        ));
      }
    } catch (e) {
      emit(FilterError(
        currentFilter: state.currentFilter,
        savedFilters: state.savedFilters,
        message: 'Failed to save filter: $e',
      ));
    }
  }

  Future<void> _onDeleteSavedFilter(
    DeleteSavedFilter event,
    Emitter<FilterState> emit,
  ) async {
    try {
      await _persistenceService.deletePreset(int.parse(event.id));
      
      final updatedSavedFilters = state.savedFilters
          .where((filter) => filter.id != event.id)
          .toList();

      if (state is FilterLoaded) {
        emit((state as FilterLoaded).copyWith(
          savedFilters: updatedSavedFilters,
        ));
      }
    } catch (e) {
      emit(FilterError(
        currentFilter: state.currentFilter,
        savedFilters: state.savedFilters,
        message: 'Failed to delete filter: $e',
      ));
    }
  }

  Future<void> _onLoadSavedFilter(
    LoadSavedFilter event,
    Emitter<FilterState> emit,
  ) async {
    try {
      final savedFilter = state.savedFilters.firstWhere(
        (filter) => filter.id == event.id,
      );
      
      // Mark as used in database
      await _persistenceService.markAsUsed(int.parse(event.id));
      
      add(ApplyFilter(savedFilter.filter));
    } catch (e) {
      emit(FilterError(
        currentFilter: state.currentFilter,
        savedFilters: state.savedFilters,
        message: 'Failed to load filter: $e',
      ));
    }
  }

  Future<void> _onClearAllFilters(
    ClearAllFilters event,
    Emitter<FilterState> emit,
  ) async {
    add(const ApplyFilter(EventFilter()));
  }

  Future<void> _onToggleFavoritesOnly(
    ToggleFavoritesOnly event,
    Emitter<FilterState> emit,
  ) async {
    final newFilter = state.currentFilter.copyWith(
      favoritesOnly: !state.currentFilter.favoritesOnly,
    );
    add(ApplyFilter(newFilter));
  }
}
