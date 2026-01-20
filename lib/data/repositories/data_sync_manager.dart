import 'event_repository.dart';

class DataSyncManager {
  final EventRepository eventRepository;

  DataSyncManager({
    required this.eventRepository,
  });

  Future<void> syncAll() async {
    await eventRepository.syncEvents();
  }

  Future<void> syncEvents() async {
    await eventRepository.syncEvents();
  }
}
