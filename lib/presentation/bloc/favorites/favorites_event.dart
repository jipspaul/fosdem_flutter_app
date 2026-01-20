import '../../bloc/base/base_event.dart';

abstract class FavoritesEvent extends BaseEvent {
  const FavoritesEvent();
}

class LoadFavorites extends FavoritesEvent {
  const LoadFavorites();
}

class AddFavorite extends FavoritesEvent {
  final String eventId;
  
  const AddFavorite(this.eventId);
  
  @override
  List<Object?> get props => [eventId];
}

class RemoveFavorite extends FavoritesEvent {
  final String eventId;
  
  const RemoveFavorite(this.eventId);
  
  @override
  List<Object?> get props => [eventId];
}

class ToggleFavorite extends FavoritesEvent {
  final String eventId;
  
  const ToggleFavorite(this.eventId);
  
  @override
  List<Object?> get props => [eventId];
}
