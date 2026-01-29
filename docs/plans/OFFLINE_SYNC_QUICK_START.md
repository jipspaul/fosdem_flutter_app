# Offline Sync - Quick Start Guide

## What Was Built

A comprehensive offline-first system with:
- 📡 Real-time connectivity monitoring
- 💾 Smart caching with TTL and LRU eviction
- 🔄 Automatic sync queue for offline operations
- 🎨 Pre-built UI components
- 💼 Backup and migration services

## Quick Integration (5 Minutes)

### 1. Initialize Services

```dart
// In your main.dart or service_locator.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initOfflineServices() async {
  final prefs = await SharedPreferences.getInstance();
  
  sl.registerLazySingleton(() => ConnectivityService());
  sl.registerLazySingleton(() => CacheManager(prefs));
  sl.registerLazySingleton(() => SyncQueueService(prefs, sl()));
  sl.registerLazySingleton(() => DataMigrationService(prefs));
  sl.registerLazySingleton(() => BackupService(prefs));
  
  // Run migration
  await sl<DataMigrationService>().migrate();
}

// Call in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initOfflineServices();
  runApp(MyApp());
}
```

### 2. Wrap Your App

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ConnectivityWrapper(
        connectivityService: sl<ConnectivityService>(),
        showBanner: true, // Shows offline/online banner
        child: YourHomePage(),
      ),
    );
  }
}
```

### 3. Use in Your Code

```dart
// Check connectivity
final connectivity = sl<ConnectivityService>();
if (connectivity.isOnline) {
  // Make API call
} else {
  // Queue for later
  await sl<SyncQueueService>().enqueue(
    SyncOperation(
      id: Uuid().v4(),
      type: SyncOperationType.addFavorite,
      status: SyncOperationStatus.pending,
      data: {'eventId': 123},
      createdAt: DateTime.now(),
    ),
  );
}

// Cache data
final cache = sl<CacheManager>();
await cache.set('events_list', jsonEncode(events));

// Retrieve cached data
final cachedData = await cache.get<String>('events_list');
```

### 4. Register Sync Handlers

```dart
void setupSyncHandlers() {
  final syncQueue = sl<SyncQueueService>();
  
  // Handle favorite additions
  syncQueue.registerHandler(
    SyncOperationType.addFavorite,
    (op) async {
      final eventId = op.data['eventId'] as int;
      await yourFavoritesRepo.addFavorite(eventId);
    },
  );
  
  // Handle favorite removals
  syncQueue.registerHandler(
    SyncOperationType.removeFavorite,
    (op) async {
      final eventId = op.data['eventId'] as int;
      await yourFavoritesRepo.removeFavorite(eventId);
    },
  );
}
```

### 5. Add UI Components (Optional)

```dart
// Show offline indicator
OfflineIndicator(
  status: connectivity.currentStatus,
  onTap: () => showDialog(...),
)

// Show sync status
StreamBuilder<SyncQueueStatus>(
  stream: sl<SyncQueueService>().statusStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox.shrink();
    return SyncStatusWidget(
      status: snapshot.data!,
      onRetryFailed: () => sl<SyncQueueService>().retryFailed(),
    );
  },
)

// Sync button
SyncButton(
  onPressed: () => yourSyncFunction(),
  isLoading: isSyncing,
)
```

## Key Features

### Connectivity Service
```dart
// Listen to connectivity changes
connectivity.statusStream.listen((status) {
  if (status == ConnectivityStatus.offline) {
    // Handle offline
  }
});

// Check current status
bool isOnline = connectivity.isOnline;
bool isWifi = connectivity.isWifi;
```

### Cache Manager
```dart
// Set with custom TTL
await cache.set('key', 'value', ttl: Duration(hours: 12));

// Get cached value
final value = await cache.get<String>('key');

// Check if cached
bool exists = await cache.has('key');

// Clear expired
await cache.clearExpired();

// Get stats
final stats = cache.getCacheStats();
// Returns: {totalSize, maxSize, entryCount, usagePercentage, lastSync}
```

### Sync Queue
```dart
// Enqueue operation
await syncQueue.enqueue(operation);

// Get pending operations
final pending = syncQueue.getPendingOperations();

// Retry failed operations
await syncQueue.retryFailed();

// Listen to status
syncQueue.statusStream.listen((status) {
  print('Pending: ${status.pendingCount}');
  print('Failed: ${status.failedCount}');
  print('Processing: ${status.isProcessing}');
});
```

### Backup Service
```dart
// Create backup
final result = await backup.createBackup();
result.fold(
  (failure) => print('Backup failed'),
  (backupId) => print('Backup created: $backupId'),
);

// List backups
final backups = await backup.listBackups();

// Restore backup
await backup.restoreBackup(backupId);

// Auto backup
await backup.autoBackup(); // Only if > 24 hours since last
```

## UI Components Reference

| Widget | Purpose |
|--------|---------|
| `ConnectivityWrapper` | App-level wrapper showing connectivity banner |
| `OfflineBanner` | Simple offline indicator with retry |
| `ConnectivityBanner` | Animated online/offline banner |
| `OfflineIndicator` | Compact status badge |
| `OfflineFloatingIndicator` | Floating overlay when offline |
| `SyncStatusWidget` | Card showing sync status |
| `SyncProgressIndicator` | Progress bar during sync |
| `SyncButton` | Button with loading state |
| `SyncOperationsList` | List of queued operations |

## Testing

```bash
# Run tests
cd fosdem_flutter
flutter test

# Check cache size
flutter run --debug
# Open app > Settings > View cache stats

# Test offline mode
# Turn off WiFi/Mobile data
# Perform actions (e.g., add favorite)
# Turn on connectivity
# Watch operations sync automatically
```

## Troubleshooting

**Queue not processing?**
- Ensure handlers are registered before operations are queued
- Check connectivity status
- Verify operation data is serializable

**Cache not working?**
- Check cache size limit (50MB default)
- Verify TTL hasn't expired
- Check SharedPreferences initialization

**UI not updating?**
- Ensure using StreamBuilder for status streams
- Check widget is mounted when updating state

## Performance Tips

1. **Cache wisely**: Cache frequently accessed, rarely changing data
2. **Set appropriate TTLs**: Shorter for dynamic data, longer for static
3. **Use priorities**: High priority for user-triggered operations
4. **Monitor queue size**: Clear completed operations regularly
5. **Backup strategically**: Auto-backup on WiFi only

## Files Location

```
lib/
├── core/services/
│   ├── connectivity_service.dart       ✅ Exists
│   ├── cache_manager.dart              ✅ New
│   ├── sync_queue_service.dart         ✅ New
│   ├── data_migration_service.dart     ✅ New
│   └── backup_service.dart             ✅ New
├── data/
│   ├── models/
│   │   └── sync_operation.dart         ✅ New
│   └── datasources/local/
│       ├── tables/
│       │   └── cache_metadata_table.dart ✅ New
│       └── daos/
│           └── cache_dao.dart          ✅ New
└── presentation/widgets/
    ├── common/
    │   └── offline_banner.dart         ✅ New
    └── offline/
        ├── offline_indicator.dart      ✅ New
        └── sync_status_widget.dart     ✅ New
```

## What's Next?

- ✅ All offline sync features implemented
- 📝 Proceed to Step 12: Testing & Optimization
- 🚀 Ready for integration and deployment

