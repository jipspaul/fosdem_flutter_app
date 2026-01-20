import '../../../domain/entities/event_domain.dart';
import '../../bloc/base/base_state.dart';

abstract class FavoritesState extends BaseState {
  const FavoritesState();
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final List<EventDomain> favorites;
  final Set<String> favoriteIds;
  
  const FavoritesLoaded({
    required this.favorites,
    required this.favoriteIds,
  });
  
  bool isFavorite(String eventId) => favoriteIds.contains(eventId);
  
  @override
  List<Object?> get props => [favorites, favoriteIds];
}

class FavoritesError extends FavoritesState {
  final String message;
  
  const FavoritesError(this.message);
  
  @override
  List<Object?> get props => [message];
}
