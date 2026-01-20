import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/data_sync_manager.dart';
import '../../bloc/base/base_bloc.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends BaseBloc<SyncEvent, SyncState> {
  final DataSyncManager _syncManager;

  SyncBloc(this._syncManager) : super(const SyncIdle()) {
    on<StartSync>(_onStartSync);
    on<CheckSyncStatus>(_onCheckSyncStatus);
    on<CancelSync>(_onCancelSync);
  }

  Future<void> _onStartSync(
    StartSync event,
    Emitter<SyncState> emit,
  ) async {
    try {
      emit(const SyncInProgress(progress: 0.0, currentTask: 'Initializing...'));
      
      emit(const SyncInProgress(progress: 0.3, currentTask: 'Syncing events...'));
      await _syncManager.syncAll();
      
      emit(const SyncInProgress(progress: 1.0, currentTask: 'Complete'));
      emit(SyncComplete(
        syncTime: DateTime.now(),
        itemsSynced: 0,
      ));
      
      await Future.delayed(const Duration(seconds: 2));
      emit(SyncIdle(lastSyncTime: DateTime.now()));
    } catch (e, stackTrace) {
      await handleError(emit, e, stackTrace);
      emit(SyncError(e.toString()));
    }
  }

  Future<void> _onCheckSyncStatus(
    CheckSyncStatus event,
    Emitter<SyncState> emit,
  ) async {
    // Could check last sync time from preferences
    emit(const SyncIdle());
  }

  Future<void> _onCancelSync(
    CancelSync event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncIdle());
  }
}
