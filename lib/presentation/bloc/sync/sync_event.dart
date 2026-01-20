import '../../bloc/base/base_event.dart';

abstract class SyncEvent extends BaseEvent {
  const SyncEvent();
}

class StartSync extends SyncEvent {
  const StartSync();
}

class CheckSyncStatus extends SyncEvent {
  const CheckSyncStatus();
}

class CancelSync extends SyncEvent {
  const CancelSync();
}
