import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// Repository interface for user favorites
abstract class FavoritesRepository {
  /// Add event to favorites
  Future<Either<Failure, void>> addFavorite(String eventId);

  /// Remove event from favorites
  Future<Either<Failure, void>> removeFavorite(String eventId);

  /// Check if event is favorited
  Future<Either<Failure, bool>> isFavorite(String eventId);

  /// Get all favorite event IDs
  Future<Either<Failure, List<String>>> getFavoriteIds();

  /// Toggle favorite status
  Future<Either<Failure, bool>> toggleFavorite(String eventId);

  /// Watch favorite changes for real-time updates
  Stream<List<String>> watchFavorites();

  /// Sync favorites with cloud (future feature)
  Future<Either<Failure, void>> syncFavorites();

  /// Clear all favorites
  Future<Either<Failure, void>> clearAllFavorites();

  /// Export favorites as JSON
  Future<Either<Failure, String>> exportFavorites();

  /// Import favorites from JSON
  Future<Either<Failure, void>> importFavorites(String json);
}
