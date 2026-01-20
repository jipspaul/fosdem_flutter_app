import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/tracks_repository.dart';
import '../datasources/local/database.dart';
import '../datasources/remote/fosdem_api.dart';
import '../models/mappers/track_mapper.dart';

class TracksRepositoryImpl implements TracksRepository {
  final AppDatabase database;
  final FosdemApi api;

  TracksRepositoryImpl({
    required this.database,
    required this.api,
  });

  @override
  Future<Either<Failure, List<Track>>> getTracks() async {
    try {
      final tracks = await database.tracksDao.getAllTracks();
      return Right(tracks.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, Track>> getTrackById(String id) async {
    try {
      final track = await database.tracksDao.getTrackById(id);
      if (track == null) {
        return Left(CacheFailure( 'Track not found'));
      }
      return Right(track.toEntity());
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getTracksByType(String type) async {
    try {
      final tracks = await database.tracksDao.getTracksByType(type);
      return Right(tracks.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> searchTracks(String query) async {
    try {
      final tracks = await database.tracksDao.searchTracks(query);
      return Right(tracks.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getEventCount(String trackId) async {
    try {
      final count = await database.tracksDao.getEventCount(trackId);
      return Right(count);
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Stream<List<Track>> watchTracks() {
    return database.tracksDao
        .watchAllTracks()
        .map((tracks) => tracks.map((t) => t.toEntity()).toList());
  }

  @override
  Future<Either<Failure, void>> syncTracks() async {
    try {
      // Fetch from API
      final result = await api.getSchedule();
      
      return result.fold(
        (failure) => Left(failure),
        (schedule) async {
          // Extract unique tracks and store in database
          final tracksSet = <String>{};
          for (final event in schedule.events) {
            if (event.track.isNotEmpty) {
              tracksSet.add(event.track);
            }
          }
          
          for (final trackName in tracksSet) {
            final track = Track(
              name: trackName,
            );
            await database.tracksDao.insertTrack(track.toCompanion());
          }
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await database.tracksDao.deleteAllTracks();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }
}
