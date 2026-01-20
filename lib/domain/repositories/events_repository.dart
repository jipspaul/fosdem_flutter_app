import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/event.dart';

/// Repository interface for event-related operations
abstract class EventsRepository {
  /// Get all events with optional pagination
  Future<Either<Failure, List<Event>>> getEvents({
    int? limit,
    int? offset,
  });

  /// Get a single event by ID
  Future<Either<Failure, Event>> getEventById(String id);

  /// Search events by query string
  Future<Either<Failure, List<Event>>> searchEvents(String query);

  /// Get events by track
  Future<Either<Failure, List<Event>>> getEventsByTrack(String trackId);

  /// Get events by date range
  Future<Either<Failure, List<Event>>> getEventsByDate({
    required DateTime startDate,
    DateTime? endDate,
  });

  /// Get events by building/room
  Future<Either<Failure, List<Event>>> getEventsByRoom(String room);

  /// Watch events for real-time updates
  Stream<List<Event>> watchEvents();

  /// Watch a specific event
  Stream<Event?> watchEvent(String id);

  /// Sync events from remote API
  Future<Either<Failure, void>> syncEvents();

  /// Get favorite events
  Future<Either<Failure, List<Event>>> getFavoriteEvents();

  /// Toggle event favorite status
  Future<Either<Failure, void>> toggleFavorite(String eventId);

  /// Check if event is favorited
  Future<Either<Failure, bool>> isFavorite(String eventId);

  /// Clear local event cache
  Future<Either<Failure, void>> clearCache();
}
