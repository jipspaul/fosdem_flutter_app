import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/building.dart';

/// Repository interface for building and map data
abstract class BuildingsRepository {
  /// Get all buildings
  Future<Either<Failure, List<Building>>> getBuildings();

  /// Get a single building by ID
  Future<Either<Failure, Building>> getBuildingById(String id);

  /// Get building by room name
  Future<Either<Failure, Building?>> getBuildingByRoom(String room);

  /// Get blueprint image for a building
  Future<Either<Failure, String>> getBlueprintUrl(String buildingId);

  /// Watch buildings for real-time updates
  Stream<List<Building>> watchBuildings();

  /// Sync buildings from remote API
  Future<Either<Failure, void>> syncBuildings();

  /// Clear local building cache
  Future<Either<Failure, void>> clearCache();
}
