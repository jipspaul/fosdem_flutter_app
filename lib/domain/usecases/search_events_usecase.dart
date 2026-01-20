import '../entities/event.dart';
import '../repositories/events_repository.dart';

class SearchEventsUseCase {
  final EventsRepository _repository;

  SearchEventsUseCase(this._repository);

  Future<List<Event>> execute(String query) async {
    if (query.isEmpty) {
      final result = await _repository.getEvents();
      return result.fold((l) => [], (r) => r);
    }
    
    final result = await _repository.searchEvents(query);
    return result.fold((l) => [], (r) => r);
  }
}
