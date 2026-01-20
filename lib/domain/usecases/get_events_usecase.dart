import '../entities/event.dart';
import '../repositories/events_repository.dart';

class GetEventsUseCase {
  final EventsRepository _repository;

  GetEventsUseCase(this._repository);

  Future<List<Event>> execute({
    String? trackId,
    DateTime? date,
    bool favoritesOnly = false,
  }) async {
    if (favoritesOnly) {
      final result = await _repository.getFavoriteEvents();
      return result.fold((l) => [], (r) => r);
    } else if (trackId != null) {
      final result = await _repository.getEventsByTrack(trackId);
      return result.fold((l) => [], (r) => r);
    } else if (date != null) {
      final result = await _repository.getEventsByDate(startDate: date);
      return result.fold((l) => [], (r) => r);
    } else {
      final result = await _repository.getEvents();
      return result.fold((l) => [], (r) => r);
    }
  }
}
