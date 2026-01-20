import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncResult {
  final SyncStatus status;
  final String? message;
  final DateTime timestamp;
  final int itemsSynced;

  SyncResult({
    required this.status,
    this.message,
    required this.timestamp,
    this.itemsSynced = 0,
  });
}

/// Service to handle data synchronization between local and remote
class SyncService {
  final List<SyncListener> _listeners = [];
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncResult? _lastResult;

  SyncStatus get currentStatus => _currentStatus;
  SyncResult? get lastResult => _lastResult;

  void addListener(SyncListener listener) {
    _listeners.add(listener);
  }

  void removeListener(SyncListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(SyncResult result) {
    _lastResult = result;
    _currentStatus = result.status;
    for (final listener in _listeners) {
      listener.onSyncStatusChanged(result);
    }
  }

  /// Perform full sync of all data
  Future<Either<Failure, SyncResult>> fullSync({
    required Future<Either<Failure, void>> Function() syncFunction,
  }) async {
    _notifyListeners(SyncResult(
      status: SyncStatus.syncing,
      timestamp: DateTime.now(),
    ));

    try {
      final result = await syncFunction();
      
      return result.fold(
        (failure) {
          final syncResult = SyncResult(
            status: SyncStatus.error,
            message: failure.message,
            timestamp: DateTime.now(),
          );
          _notifyListeners(syncResult);
          return Left(failure);
        },
        (_) {
          final syncResult = SyncResult(
            status: SyncStatus.success,
            message: 'Sync completed successfully',
            timestamp: DateTime.now(),
            itemsSynced: 1,
          );
          _notifyListeners(syncResult);
          return Right(syncResult);
        },
      );
    } catch (e) {
      final syncResult = SyncResult(
        status: SyncStatus.error,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
      _notifyListeners(syncResult);
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Perform incremental sync (only changed data)
  Future<Either<Failure, SyncResult>> incrementalSync({
    required Future<Either<Failure, void>> Function(DateTime lastSync) syncFunction,
    required DateTime lastSyncTime,
  }) async {
    _notifyListeners(SyncResult(
      status: SyncStatus.syncing,
      timestamp: DateTime.now(),
    ));

    try {
      final result = await syncFunction(lastSyncTime);
      
      return result.fold(
        (failure) {
          final syncResult = SyncResult(
            status: SyncStatus.error,
            message: failure.message,
            timestamp: DateTime.now(),
          );
          _notifyListeners(syncResult);
          return Left(failure);
        },
        (_) {
          final syncResult = SyncResult(
            status: SyncStatus.success,
            message: 'Incremental sync completed',
            timestamp: DateTime.now(),
          );
          _notifyListeners(syncResult);
          return Right(syncResult);
        },
      );
    } catch (e) {
      final syncResult = SyncResult(
        status: SyncStatus.error,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
      _notifyListeners(syncResult);
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Resolve conflicts when local and remote data differ
  Future<T> resolveConflict<T>({
    required T localData,
    required T remoteData,
    required ConflictResolutionStrategy strategy,
  }) async {
    switch (strategy) {
      case ConflictResolutionStrategy.preferLocal:
        return localData;
      case ConflictResolutionStrategy.preferRemote:
        return remoteData;
      case ConflictResolutionStrategy.preferNewer:
        // Would need timestamp comparison
        return remoteData;
      case ConflictResolutionStrategy.manual:
        // Would require user input
        return remoteData;
    }
  }
}

enum ConflictResolutionStrategy {
  preferLocal,
  preferRemote,
  preferNewer,
  manual,
}

abstract class SyncListener {
  void onSyncStatusChanged(SyncResult result);
}
