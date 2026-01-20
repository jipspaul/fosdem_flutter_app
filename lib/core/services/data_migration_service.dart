import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../errors/failures.dart';

class DataMigrationService {
  final SharedPreferences _prefs;
  static const String _versionKey = 'app_data_version';
  static const int _currentVersion = 1;

  DataMigrationService(this._prefs);

  Future<void> migrate() async {
    final currentVersion = _prefs.getInt(_versionKey) ?? 0;
    
    if (currentVersion < _currentVersion) {
      for (var version = currentVersion + 1; version <= _currentVersion; version++) {
        await _runMigration(version);
      }
      await _prefs.setInt(_versionKey, _currentVersion);
    }
  }

  Future<void> _runMigration(int toVersion) async {
    switch (toVersion) {
      case 1:
        await _migrateToV1();
        break;
      default:
        break;
    }
  }

  Future<void> _migrateToV1() async {
    // Initial setup - no migration needed
  }

  int getCurrentVersion() => _prefs.getInt(_versionKey) ?? 0;

  Future<bool> needsMigration() async {
    final version = getCurrentVersion();
    return version < _currentVersion;
  }

  Future<void> validateData() async {
    // Validate cache integrity
    final cacheKeys = _prefs.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in cacheKeys) {
      final value = _prefs.getString(key);
      if (value == null || value.isEmpty) {
        await _prefs.remove(key);
      }
    }
  }

  Future<Map<String, dynamic>> getDataStats() async {
    final allKeys = _prefs.getKeys();
    final cacheKeys = allKeys.where((k) => k.startsWith('cache_')).length;
    final syncKeys = allKeys.where((k) => k.startsWith('sync_')).length;
    
    return {
      'version': getCurrentVersion(),
      'totalKeys': allKeys.length,
      'cacheKeys': cacheKeys,
      'syncKeys': syncKeys,
      'needsMigration': await needsMigration(),
    };
  }

  Future<void> resetToVersion(int version) async {
    if (version >= 0 && version <= _currentVersion) {
      await _prefs.setInt(_versionKey, version);
    }
  }
}
