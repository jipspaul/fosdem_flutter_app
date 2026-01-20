import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/sync_operation.dart';
import 'connectivity_service.dart';

typedef SyncOperationHandler = Future<void> Function(SyncOperation operation);

class SyncQueueService {
  final SharedPreferences _prefs;
  final ConnectivityService _connectivityService;
  final Map<SyncOperationType, SyncOperationHandler> _handlers = {};
  
  static const String _queueKey = 'sync_queue';
  static const Duration _retryDelay = Duration(seconds: 5);
  
  Timer? _processingTimer;
  bool _isProcessing = false;
  final List<SyncOperation> _queue = [];
  final _statusController = StreamController<SyncQueueStatus>.broadcast();

  SyncQueueService(this._prefs, this._connectivityService) {
    _loadQueue();
    _startProcessing();
    _connectivityService.statusStream.listen((_) => _triggerProcessing());
  }

  Stream<SyncQueueStatus> get statusStream => _statusController.stream;

  void registerHandler(SyncOperationType type, SyncOperationHandler handler) {
    _handlers[type] = handler;
  }

  Future<void> _loadQueue() async {
    final queueJson = _prefs.getString(_queueKey);
    if (queueJson != null) {
      try {
        final List<dynamic> list = jsonDecode(queueJson);
        _queue.clear();
        _queue.addAll(list.map((json) => SyncOperation.fromJson(json)));
        _emitStatus();
      } catch (e) {
        _queue.clear();
      }
    }
  }

  Future<void> _saveQueue() async {
    final json = jsonEncode(_queue.map((op) => op.toJson()).toList());
    await _prefs.setString(_queueKey, json);
    _emitStatus();
  }

  Future<String> enqueue(SyncOperation operation) async {
    _queue.add(operation);
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    await _saveQueue();
    _triggerProcessing();
    return operation.id;
  }

  Future<void> remove(String operationId) async {
    _queue.removeWhere((op) => op.id == operationId);
    await _saveQueue();
  }

  Future<void> clear() async {
    _queue.clear();
    await _saveQueue();
  }

  List<SyncOperation> getPendingOperations() => 
    _queue.where((op) => op.isPending).toList();

  List<SyncOperation> getFailedOperations() =>
    _queue.where((op) => op.isFailed).toList();

  int get pendingCount => getPendingOperations().length;
  int get failedCount => getFailedOperations().length;

  void _startProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _processQueue());
  }

  void _triggerProcessing() {
    if (!_isProcessing && _connectivityService.isOnline) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing || !_connectivityService.isOnline) return;
    
    _isProcessing = true;
    try {
      final pending = getPendingOperations();
      
      for (final operation in pending) {
        if (!_connectivityService.isOnline) break;

        try {
          final handler = _handlers[operation.type];
          if (handler == null) {
            await _updateOperation(operation.copyWith(
              status: SyncOperationStatus.failed,
              error: 'No handler registered',
            ));
            continue;
          }

          final updatedOp = operation.copyWith(status: SyncOperationStatus.inProgress);
          await _updateOperation(updatedOp);

          await handler(operation);

          await _updateOperation(operation.copyWith(
            status: SyncOperationStatus.completed,
            completedAt: DateTime.now(),
          ));

          await remove(operation.id);
        } catch (e) {
          await _handleOperationError(operation, e.toString());
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _handleOperationError(SyncOperation operation, String error) async {
    final newRetryCount = operation.retryCount + 1;
    
    if (operation.canRetry && newRetryCount < operation.maxRetries) {
      await _updateOperation(operation.copyWith(
        status: SyncOperationStatus.pending,
        retryCount: newRetryCount,
        error: error,
      ));
      
      await Future.delayed(_retryDelay);
    } else {
      await _updateOperation(operation.copyWith(
        status: SyncOperationStatus.failed,
        retryCount: newRetryCount,
        error: error,
      ));
    }
  }

  Future<void> _updateOperation(SyncOperation updated) async {
    final index = _queue.indexWhere((op) => op.id == updated.id);
    if (index != -1) {
      _queue[index] = updated;
      await _saveQueue();
    }
  }

  Future<void> retryFailed() async {
    final failed = getFailedOperations();
    for (final op in failed) {
      if (op.canRetry) {
        await _updateOperation(op.copyWith(
          status: SyncOperationStatus.pending,
          retryCount: 0,
          error: null,
        ));
      }
    }
    _triggerProcessing();
  }

  void _emitStatus() {
    _statusController.add(SyncQueueStatus(
      pendingCount: pendingCount,
      failedCount: failedCount,
      isProcessing: _isProcessing,
    ));
  }

  void dispose() {
    _processingTimer?.cancel();
    _statusController.close();
  }
}

class SyncQueueStatus {
  final int pendingCount;
  final int failedCount;
  final bool isProcessing;

  SyncQueueStatus({
    required this.pendingCount,
    required this.failedCount,
    required this.isProcessing,
  });
}
