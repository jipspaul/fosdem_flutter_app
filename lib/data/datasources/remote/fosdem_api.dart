import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/track.dart';
import '../../../core/services/http_client.dart';
import 'schedule_api.dart';

/// Main API client for FOSDEM data
class FosdemApi {
  final Dio dio;
  late final ScheduleApi scheduleApi;

  FosdemApi(this.dio) {
    // Initialize specific API endpoints
    scheduleApi = ScheduleApi(
      httpClient: _createHttpClient(),
    );
  }

  _createHttpClient() {
    // Create HttpClient wrapper for ScheduleApi
    return _DioHttpClientAdapter(dio);
  }

  /// Get the full schedule
  Future<Either<Failure, Schedule>> getSchedule({int? year}) async {
    try {
      final scheduleEntity = year != null 
          ? await scheduleApi.fetchSchedule(year)
          : await scheduleApi.fetchLatestSchedule();
      
      // Convert ScheduleEntity to Schedule domain model
      final schedule = Schedule(
        events: scheduleEntity.events.map((e) => Event(
          id: e.id,
          title: e.title,
          subtitle: e.subtitle,
          abstract: e.abstract,
          description: e.description,
          room: e.room,
          track: e.track ?? '',
          date: e.startTime,
          start: e.startTime,
          duration: e.duration,
          isSync: false,
        )).toList(),
        tracks: scheduleEntity.tracks.map((t) => Track(name: t.name)).toList(),
        lastUpdated: scheduleEntity.lastUpdated,
        year: scheduleEntity.year,
      );
      
      return Right(schedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get events with optional filters
  Future<Either<Failure, List<dynamic>>> getEvents({
    int? year,
    String? track,
    String? room,
  }) async {
    try {
      final events = await scheduleApi.fetchEvents(
        year: year,
        track: track,
        room: room,
      );
      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get all tracks
  Future<Either<Failure, List<dynamic>>> getTracks({int? year}) async {
    try {
      final tracks = await scheduleApi.fetchTracks(
        year ?? 2025,
      );
      return Right(tracks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Check if there are updates available
  Future<Either<Failure, bool>> hasUpdates({
    required int year,
    required DateTime lastFetch,
  }) async {
    try {
      final hasUpdate = await scheduleApi.hasUpdates(year, lastFetch);
      return Right(hasUpdate);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// HttpClient adapter that wraps Dio and extends our HttpClient class
class _DioHttpClientAdapter extends HttpClient {
  _DioHttpClientAdapter(Dio dio) : super() {
    _dio = dio;
  }
  
  late Dio _dio;
  
  @override
  Dio get client => _dio;
}
