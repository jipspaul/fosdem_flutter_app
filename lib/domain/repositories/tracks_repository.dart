import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/track.dart';

/// Repository interface for track-related operations
abstract class TracksRepository {
  /// Get all tracks
  Future<Either<Failure, List<Track>>> getTracks();

  /// Get a single track by ID
  Future<Either<Failure, Track>> getTrackById(String id);

  /// Get tracks by type (devroom, main track, etc.)
  Future<Either<Failure, List<Track>>> getTracksByType(String type);

  /// Search tracks by name
  Future<Either<Failure, List<Track>>> searchTracks(String query);

  /// Get event count for a track
  Future<Either<Failure, int>> getEventCount(String trackId);

  /// Watch tracks for real-time updates
  Stream<List<Track>> watchTracks();

  /// Sync tracks from remote API
  Future<Either<Failure, void>> syncTracks();

  /// Clear local track cache
  Future<Either<Failure, void>> clearCache();
}
