import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

enum CachePolicy {
  networkFirst,
  cacheFirst,
  networkOnly,
  cacheOnly,
  staleWhileRevalidate,
}

class CacheEntry {
  final String key;
  final DateTime timestamp;
  final int size;
  final Duration ttl;

  CacheEntry({
    required this.key,
    required this.timestamp,
    required this.size,
    this.ttl = const Duration(hours: 24),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

class CacheManager {
  final SharedPreferences _prefs;
  final Map<String, CacheEntry> _cacheIndex = {};
  final Duration _defaultTtl = const Duration(hours: 24);
  final int _maxCacheSize = 50 * 1024 * 1024;

  static const String _cacheKeyPrefix = 'cache_';
  static const String _cacheTimestampPrefix = 'cache_ts_';
  static const String _cacheSizeKey = 'total_cache_size';
  static const String _lastSyncKey = 'last_sync_time';

  CacheManager(this._prefs) {
    _loadCacheIndex();
  }

  void _loadCacheIndex() {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));
    for (final key in keys) {
      final cacheKey = key.substring(_cacheKeyPrefix.length);
      final timestamp = _prefs.getInt('$_cacheTimestampPrefix$cacheKey');
      if (timestamp != null) {
        _cacheIndex[cacheKey] = CacheEntry(
          key: cacheKey,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
          size: 0,
        );
      }
    }
  }

  Future<T?> get<T>(String key, {T Function(String)? deserializer}) async {
    final cacheKey = '$_cacheKeyPrefix$key';
    final entry = _cacheIndex[key];

    if (entry != null && entry.isExpired) {
      await remove(key);
      return null;
    }

    final value = _prefs.getString(cacheKey);
    if (value == null) return null;

    return deserializer != null ? deserializer(value) : value as T;
  }

  Future<void> set(String key, String value, {Duration? ttl}) async {
    final cacheKey = '$_cacheKeyPrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';
    final size = value.length;
    
    if (await _shouldEvictCache(size)) {
      await _evictOldestEntries(size);
    }

    await _prefs.setString(cacheKey, value);
    await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

    _cacheIndex[key] = CacheEntry(
      key: key,
      timestamp: DateTime.now(),
      size: size,
      ttl: ttl ?? _defaultTtl,
    );

    await _updateCacheSize();
  }

  Future<void> remove(String key) async {
    await _prefs.remove('$_cacheKeyPrefix$key');
    await _prefs.remove('$_cacheTimestampPrefix$key');
    _cacheIndex.remove(key);
    await _updateCacheSize();
  }

  Future<void> clear() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix) || k.startsWith(_cacheTimestampPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
    _cacheIndex.clear();
    await _prefs.setInt(_cacheSizeKey, 0);
  }

  Future<void> clearExpired() async {
    final expiredKeys = _cacheIndex.entries.where((e) => e.value.isExpired).map((e) => e.key).toList();
    for (final key in expiredKeys) {
      await remove(key);
    }
  }

  Future<bool> has(String key) async {
    final entry = _cacheIndex[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      await remove(key);
      return false;
    }
    return true;
  }

  int get currentSize => _cacheIndex.values.fold(0, (sum, entry) => sum + entry.size);
  int get entryCount => _cacheIndex.length;

  Map<String, dynamic> getCacheStats() => {
    'totalSize': currentSize,
    'maxSize': _maxCacheSize,
    'entryCount': entryCount,
    'usagePercentage': (currentSize / _maxCacheSize * 100).toStringAsFixed(2),
    'lastSync': _prefs.getInt(_lastSyncKey),
  };

  Future<void> setLastSyncTime(DateTime time) async => await _prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  
  DateTime? getLastSyncTime() {
    final timestamp = _prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<bool> _shouldEvictCache(int newEntrySize) async => (currentSize + newEntrySize) > _maxCacheSize;

  Future<void> _evictOldestEntries(int requiredSpace) async {
    final sortedEntries = _cacheIndex.entries.toList()..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
    var freedSpace = 0;
    for (final entry in sortedEntries) {
      if (freedSpace >= requiredSpace) break;
      await remove(entry.key);
      freedSpace += entry.value.size;
    }
  }

  Future<void> _updateCacheSize() async => await _prefs.setInt(_cacheSizeKey, currentSize);
}
