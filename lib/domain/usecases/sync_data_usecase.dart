import '../../data/repositories/data_sync_manager.dart';

class SyncDataUseCase {
  final DataSyncManager _syncManager;

  SyncDataUseCase(this._syncManager);

  Future<void> execute({bool forceSync = false}) async {
    await _syncManager.syncAll();
  }

  Future<DateTime?> getLastSyncTime() async {
    // Could be implemented with shared preferences
    return null;
  }
}
