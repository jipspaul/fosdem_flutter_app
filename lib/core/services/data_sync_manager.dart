import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../errors/failures.dart';
import '../../domain/repositories/events_repository.dart';
import '../../domain/repositories/tracks_repository.dart';
import '../../domain/repositories/buildings_repository.dart';
import 'sync_service.dart';

/// Manages synchronization across multiple repositories
class DataSyncManager {
  final EventsRepository eventsRepository;
  final TracksRepository tracksRepository;
  final BuildingsRepository buildingsRepository;
  final SyncService syncService;
  final Connectivity connectivity;

  DataSyncManager({
    required this.eventsRepository,
    required this.tracksRepository,
    required this.buildingsRepository,
    required this.syncService,
    required this.connectivity,
  });

  /// Sync all data with priority ordering
  Future<Either<Failure, Map<String, SyncResult>>> syncAll({
    bool forceFullSync = false,
  }) async {
    // Check network connectivity
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return Left(NetworkFailure('No internet connection'));
    }

    final results = <String, SyncResult>{};

    // Priority 1: Buildings (static, small dataset)
    final buildingsResult = await _syncWithPriority(
      'buildings',
      () => buildingsRepository.syncBuildings(),
    );
    buildingsResult.fold(
      (failure) => results['buildings'] = SyncResult(
        status: SyncStatus.error,
        message: failure.message,
        timestamp: DateTime.now(),
      ),
      (result) => results['buildings'] = result,
    );

    // Priority 2: Tracks (small dataset, needed for filtering)
    final tracksResult = await _syncWithPriority(
      'tracks',
      () => tracksRepository.syncTracks(),
    );
    tracksResult.fold(
      (failure) => results['tracks'] = SyncResult(
        status: SyncStatus.error,
        message: failure.message,
        timestamp: DateTime.now(),
      ),
      (result) => results['tracks'] = result,
    );

    // Priority 3: Events (large dataset, most important)
    final eventsResult = await _syncWithPriority(
      'events',
      () => eventsRepository.syncEvents(),
    );
    eventsResult.fold(
      (failure) => results['events'] = SyncResult(
        status: SyncStatus.error,
        message: failure.message,
        timestamp: DateTime.now(),
      ),
      (result) => results['events'] = result,
    );

    // Check if any sync failed
    final hasError = results.values.any((r) => r.status == SyncStatus.error);
    if (hasError) {
      return Left(SyncFailure('Some syncs failed'));
    }

    return Right(results);
  }

  Future<Either<Failure, SyncResult>> _syncWithPriority(
    String name,
    Future<Either<Failure, void>> Function() syncFunction,
  ) async {
    return syncService.fullSync(syncFunction: syncFunction);
  }

  /// Check if sync is needed based on last sync time
  bool shouldSync({
    DateTime? lastSyncTime,
    Duration syncInterval = const Duration(hours: 1),
  }) {
    if (lastSyncTime == null) return true;
    return DateTime.now().difference(lastSyncTime) > syncInterval;
  }

  /// Background sync with network awareness
  Future<Either<Failure, Map<String, SyncResult>>> backgroundSync() async {
    final connectivityResult = await connectivity.checkConnectivity();
    
    // Only sync on WiFi for background sync to save data
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return syncAll();
    }
    
    return Left(NetworkFailure('WiFi required for background sync'));
  }

  /// Get sync progress as a stream
  Stream<double> getSyncProgress() async* {
    // Simplified progress tracking
    yield 0.0;
    yield 0.33; // Buildings done
    yield 0.66; // Tracks done
    yield 1.0;  // Events done
  }

  /// Clear all local caches
  Future<Either<Failure, void>> clearAllCaches() async {
    try {
      await eventsRepository.clearCache();
      await tracksRepository.clearCache();
      await buildingsRepository.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

class SyncFailure extends Failure {
  const SyncFailure([super.message = 'Sync failed']);
}
