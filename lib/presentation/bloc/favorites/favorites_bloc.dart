import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/event_repository.dart';
import '../../bloc/base/base_bloc.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends BaseBloc<FavoritesEvent, FavoritesState> {
  final EventRepository _repository;

  FavoritesBloc(this._repository) : super(const FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddFavorite>(_onAddFavorite);
    on<RemoveFavorite>(_onRemoveFavorite);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      emit(const FavoritesLoading());
      final favorites = await _repository.getFavoriteEvents();
      final favoriteIds = favorites.map((e) => e.id.toString()).toSet();
      emit(FavoritesLoaded(favorites: favorites, favoriteIds: favoriteIds));
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onAddFavorite(
    AddFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _repository.addFavorite(event.eventId);
      add(const LoadFavorites());
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _repository.removeFavorite(event.eventId);
      add(const LoadFavorites());
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      // Check current favorite status from database
      final eventId = int.tryParse(event.eventId);
      if (eventId == null) return;
      
      final currentEvent = await _repository.database.eventsDao.getEventById(event.eventId);
      if (currentEvent == null) return;
      
      if (currentEvent.isFavorite) {
        await _repository.removeFavorite(event.eventId);
      } else {
        await _repository.addFavorite(event.eventId);
      }
      
      // Reload favorites
      add(const LoadFavorites());
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(FavoritesError(e.toString()));
    }
  }
}
