import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

class BackupData {
  final Map<String, dynamic> preferences;
  final DateTime timestamp;
  final String version;

  BackupData({
    required this.preferences,
    required this.timestamp,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
    'preferences': preferences,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
  };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
    preferences: json['preferences'] as Map<String, dynamic>,
    timestamp: DateTime.parse(json['timestamp'] as String),
    version: json['version'] as String,
  );
}

class BackupService {
  final SharedPreferences _prefs;
  static const String _backupKey = 'app_backup_';
  static const String _lastBackupKey = 'last_backup_time';
  static const int _maxBackups = 5;

  BackupService(this._prefs);

  Future<Either<Failure, String>> createBackup() async {
    try {
      final backupId = DateTime.now().millisecondsSinceEpoch.toString();
      final allKeys = _prefs.getKeys();
      final preferences = <String, dynamic>{};

      for (final key in allKeys) {
        if (key.startsWith(_backupKey)) continue;
        
        final value = _prefs.get(key);
        if (value != null) {
          preferences[key] = value;
        }
      }

      final backup = BackupData(
        preferences: preferences,
        timestamp: DateTime.now(),
        version: '1.0',
      );

      final backupJson = jsonEncode(backup.toJson());
      await _prefs.setString('$_backupKey$backupId', backupJson);
      await _prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);

      await _cleanOldBackups();

      return Right(backupId);
    } catch (e) {
      return Left(CacheFailure('Failed to create backup: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> restoreBackup(String backupId) async {
    try {
      final backupJson = _prefs.getString('$_backupKey$backupId');
      if (backupJson == null) {
        return Left(CacheFailure('Backup not found'));
      }

      final backup = BackupData.fromJson(jsonDecode(backupJson));

      // Clear current data (except backups)
      final allKeys = _prefs.getKeys().where((k) => !k.startsWith(_backupKey)).toList();
      for (final key in allKeys) {
        await _prefs.remove(key);
      }

      // Restore backup data
      for (final entry in backup.preferences.entries) {
        final value = entry.value;
        if (value is String) {
          await _prefs.setString(entry.key, value);
        } else if (value is int) {
          await _prefs.setInt(entry.key, value);
        } else if (value is double) {
          await _prefs.setDouble(entry.key, value);
        } else if (value is bool) {
          await _prefs.setBool(entry.key, value);
        } else if (value is List<String>) {
          await _prefs.setStringList(entry.key, value);
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to restore backup: ${e.toString()}'));
    }
  }

  Future<List<BackupInfo>> listBackups() async {
    final backupKeys = _prefs.getKeys().where((k) => k.startsWith(_backupKey)).toList();
    final backups = <BackupInfo>[];

    for (final key in backupKeys) {
      final backupJson = _prefs.getString(key);
      if (backupJson != null) {
        try {
          final backup = BackupData.fromJson(jsonDecode(backupJson));
          final backupId = key.substring(_backupKey.length);
          backups.add(BackupInfo(
            id: backupId,
            timestamp: backup.timestamp,
            version: backup.version,
            size: backupJson.length,
            itemCount: backup.preferences.length,
          ));
        } catch (e) {
          // Skip invalid backups
        }
      }
    }

    backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return backups;
  }

  Future<void> deleteBackup(String backupId) async {
    await _prefs.remove('$_backupKey$backupId');
  }

  Future<void> _cleanOldBackups() async {
    final backups = await listBackups();
    if (backups.length > _maxBackups) {
      final toDelete = backups.skip(_maxBackups);
      for (final backup in toDelete) {
        await deleteBackup(backup.id);
      }
    }
  }

  DateTime? getLastBackupTime() {
    final timestamp = _prefs.getInt(_lastBackupKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<bool> shouldAutoBackup({Duration interval = const Duration(days: 1)}) async {
    final lastBackup = getLastBackupTime();
    if (lastBackup == null) return true;
    return DateTime.now().difference(lastBackup) > interval;
  }

  Future<Either<Failure, void>> autoBackup() async {
    if (await shouldAutoBackup()) {
      final result = await createBackup();
      return result.fold(
        (failure) => Left(failure),
        (_) => const Right(null),
      );
    }
    return const Right(null);
  }

  Future<Map<String, dynamic>> getBackupStats() async {
    final backups = await listBackups();
    final totalSize = backups.fold<int>(0, (sum, b) => sum + b.size);
    final lastBackup = getLastBackupTime();

    return {
      'count': backups.length,
      'totalSize': totalSize,
      'lastBackup': lastBackup?.toIso8601String(),
      'oldestBackup': backups.isEmpty ? null : backups.last.timestamp.toIso8601String(),
      'newestBackup': backups.isEmpty ? null : backups.first.timestamp.toIso8601String(),
    };
  }
}

class BackupInfo {
  final String id;
  final DateTime timestamp;
  final String version;
  final int size;
  final int itemCount;

  BackupInfo({
    required this.id,
    required this.timestamp,
    required this.version,
    required this.size,
    required this.itemCount,
  });
}
