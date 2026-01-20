import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object> get props => [];
}

class LoadFavorites extends FavoritesEvent {}

class AddFavoriteEvent extends FavoritesEvent {
  final int eventId;

  const AddFavoriteEvent(this.eventId);

  @override
  List<Object> get props => [eventId];
}

class RemoveFavoriteEvent extends FavoritesEvent {
  final int eventId;

  const RemoveFavoriteEvent(this.eventId);

  @override
  List<Object> get props => [eventId];
}

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final Set<int> favoriteEventIds;

  const FavoritesLoaded(this.favoriteEventIds);

  @override
  List<Object> get props => [favoriteEventIds];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final Set<int> _favoriteEventIds = {};

  FavoritesBloc() : super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddFavoriteEvent>(_onAddFavorite);
    on<RemoveFavoriteEvent>(_onRemoveFavorite);
  }

  void _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    try {
      // TODO: Load from repository
      emit(FavoritesLoaded(Set.from(_favoriteEventIds)));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  void _onAddFavorite(
    AddFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      _favoriteEventIds.add(event.eventId);
      // TODO: Save to repository
      emit(FavoritesLoaded(Set.from(_favoriteEventIds)));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  void _onRemoveFavorite(
    RemoveFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      _favoriteEventIds.remove(event.eventId);
      // TODO: Save to repository
      emit(FavoritesLoaded(Set.from(_favoriteEventIds)));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }
}
