import '../../bloc/base/base_state.dart';

abstract class SyncState extends BaseState {
  const SyncState();
}

class SyncIdle extends SyncState {
  final DateTime? lastSyncTime;
  
  const SyncIdle({this.lastSyncTime});
  
  @override
  List<Object?> get props => [lastSyncTime];
}

class SyncInProgress extends SyncState {
  final double progress;
  final String currentTask;
  
  const SyncInProgress({
    required this.progress,
    required this.currentTask,
  });
  
  @override
  List<Object?> get props => [progress, currentTask];
}

class SyncComplete extends SyncState {
  final DateTime syncTime;
  final int itemsSynced;
  
  const SyncComplete({
    required this.syncTime,
    required this.itemsSynced,
  });
  
  @override
  List<Object?> get props => [syncTime, itemsSynced];
}

class SyncError extends SyncState {
  final String message;
  
  const SyncError(this.message);
  
  @override
  List<Object?> get props => [message];
}
