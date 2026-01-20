import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// Base repository interface with common CRUD operations
abstract class BaseRepository<T, ID> {
  /// Get all items with optional pagination
  Future<Either<Failure, List<T>>> getAll({
    int? limit,
    int? offset,
  });

  /// Get a single item by ID
  Future<Either<Failure, T>> getById(String id);

  /// Create a new item
  Future<Either<Failure, T>> create(T item);

  /// Update an existing item
  Future<Either<Failure, T>> update(T item);

  /// Delete an item by ID
  Future<Either<Failure, void>> delete(String id);

  /// Stream of items for real-time updates
  Stream<List<T>> watchAll<T>();

  /// Sync local data with remote
  Future<Either<Failure, void>> sync();

  /// Clear local cache
  Future<Either<Failure, void>> clearCache();
}

abstract class PaginatedRepository<T> {
  Future<Either<Failure, List<T>>> getPage({
    required int page,
    required int pageSize,
    Map<String, dynamic>? filters,
  });
}
