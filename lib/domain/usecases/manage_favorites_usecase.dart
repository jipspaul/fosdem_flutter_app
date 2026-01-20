import '../repositories/events_repository.dart';

class ManageFavoritesUseCase {
  final EventsRepository _repository;

  ManageFavoritesUseCase(this._repository);

  Future<void> toggleFavorite(String eventId) async {
    await _repository.toggleFavorite(eventId);
  }

  Future<bool> isFavorite(String eventId) async {
    final result = await _repository.isFavorite(eventId);
    return result.fold((l) => false, (r) => r);
  }
}
