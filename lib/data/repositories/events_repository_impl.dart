import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/local/database.dart';
import '../datasources/remote/fosdem_api.dart';
import '../models/mappers/event_mapper.dart';

class EventsRepositoryImpl implements EventsRepository {
  final AppDatabase database;
  final FosdemApi api;

  EventsRepositoryImpl({
    required this.database,
    required this.api,
  });

  @override
  Future<Either<Failure, List<Event>>> getEvents({
    int? limit,
    int? offset,
  }) async {
    try {
      final events = await database.eventsDao.getAllEvents(
        limit: limit,
        offset: offset,
      );
      return Right(events.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Event>> getEventById(String id) async {
    try {
      final event = await database.eventsDao.getEventById(id);
      if (event == null) {
        return Left(CacheFailure('Event not found'));
      }
      return Right(event.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> searchEvents(String query) async {
    try {
      final events = await database.eventsDao.searchEvents(query);
      return Right(events.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByTrack(String trackId) async {
    try {
      final events = await database.eventsDao.getEventsByTrack(trackId);
      return Right(events.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByDate({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await database.eventsDao.getEventsByDateRange(
        startDate,
        endDate ?? startDate.add(const Duration(days: 1)),
      );
      return Right(events.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByRoom(String room) async {
    try {
      final events = await database.eventsDao.getEventsByRoom(room);
      return Right(events.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<Event>> watchEvents() {
    return database.eventsDao
        .watchAllEvents()
        .map((events) => events.map((e) => e.toEntity()).toList());
  }

  @override
  Stream<Event?> watchEvent(String id) {
    return database.eventsDao
        .watchEvent(id)
        .map((event) => event?.toEntity());
  }

  @override
  Future<Either<Failure, void>> syncEvents() async {
    try {
      // Fetch from API
      final result = await api.getSchedule();
      
      return result.fold(
        (failure) => Left(failure),
        (schedule) async {
          // Store in database
          for (final event in schedule.events) {
            await database.eventsDao.insertEvent(event.toCompanion());
          }
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getFavoriteEvents() async {
    try {
      final events = await database.eventsDao.getFavoriteEvents();
      return Right(events.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(String eventId) async {
    try {
      final isFav = await database.eventsDao.isFavorite(eventId);
      await database.eventsDao.setFavorite(eventId, !isFav);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFavorite(String eventId) async {
    try {
      final result = await database.eventsDao.isFavorite(eventId);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await database.eventsDao.deleteAllEvents();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
