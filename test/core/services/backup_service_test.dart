import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fosdem_flutter/core/services/backup_service.dart';
import 'package:dartz/dartz.dart';

void main() {
  group('BackupService', () {
    late BackupService backupService;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      backupService = BackupService(prefs);
    });

    group('Backup Creation', () {
      test('should create backup successfully', () async {
        // Add some test data
        await prefs.setString('test_key', 'test_value');
        await prefs.setInt('test_int', 42);
        await prefs.setBool('test_bool', true);

        final result = await backupService.createBackup();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (backupId) => expect(backupId, isNotEmpty),
        );
      });

      test('should store backup metadata', () async {
        await prefs.setString('data', 'value');
        await backupService.createBackup();

        final backups = await backupService.listBackups();
        expect(backups.length, equals(1));
        expect(backups.first.itemCount, greaterThan(0));
      });

      test('should update last backup time', () async {
        expect(backupService.getLastBackupTime(), isNull);

        await backupService.createBackup();

        final lastBackup = backupService.getLastBackupTime();
        expect(lastBackup, isNotNull);
        expect(lastBackup!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      });

      test('should maintain maximum backup limit', () async {
        // Create 7 backups (max is 5)
        for (int i = 0; i < 7; i++) {
          await prefs.setString('data_$i', 'value_$i');
          await backupService.createBackup();
          await Future.delayed(const Duration(milliseconds: 10)); // Ensure different timestamps
        }

        final backups = await backupService.listBackups();
        expect(backups.length, lessThanOrEqualTo(5));
      });
    });

    group('Backup Restoration', () {
      test('should restore backup successfully', () async {
        // Create initial data and backup
        await prefs.setString('original_key', 'original_value');
        await prefs.setInt('original_int', 123);

        final createResult = await backupService.createBackup();
        final backupId = createResult.getOrElse(() => '');

        // Modify data
        await prefs.setString('original_key', 'modified_value');
        await prefs.setString('new_key', 'new_value');

        // Restore
        final restoreResult = await backupService.restoreBackup(backupId);

        expect(restoreResult.isRight(), isTrue);
        expect(prefs.getString('original_key'), equals('original_value'));
        expect(prefs.getInt('original_int'), equals(123));
        expect(prefs.getString('new_key'), isNull); // Should be removed
      });

      test('should fail to restore non-existent backup', () async {
        final result = await backupService.restoreBackup('non-existent-id');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.message, contains('not found')),
          (_) => fail('Should fail'),
        );
      });
    });

    group('Backup Management', () {
      test('should list all backups in reverse chronological order', () async {
        for (int i = 0; i < 3; i++) {
          await backupService.createBackup();
          await Future.delayed(const Duration(milliseconds: 10));
        }

        final backups = await backupService.listBackups();
        expect(backups.length, equals(3));

        // Verify chronological order (newest first)
        for (int i = 0; i < backups.length - 1; i++) {
          expect(
            backups[i].timestamp.isAfter(backups[i + 1].timestamp),
            isTrue,
          );
        }
      });

      test('should delete specific backup', () async {
        final result = await backupService.createBackup();
        final backupId = result.getOrElse(() => '');

        var backups = await backupService.listBackups();
        expect(backups.length, equals(1));

        await backupService.deleteBackup(backupId);

        backups = await backupService.listBackups();
        expect(backups.length, equals(0));
      });

      test('should get backup statistics', () async {
        await backupService.createBackup();
        await Future.delayed(const Duration(milliseconds: 10));
        await backupService.createBackup();

        final stats = await backupService.getBackupStats();

        expect(stats['count'], equals(2));
        expect(stats['totalSize'], greaterThan(0));
        expect(stats['lastBackup'], isNotNull);
        expect(stats['newestBackup'], isNotNull);
        expect(stats['oldestBackup'], isNotNull);
      });
    });

    group('Auto Backup', () {
      test('shouldAutoBackup returns true when no backup exists', () async {
        final should = await backupService.shouldAutoBackup();
        expect(should, isTrue);
      });

      test('shouldAutoBackup respects interval', () async {
        await backupService.createBackup();

        var should = await backupService.shouldAutoBackup(
          interval: const Duration(hours: 1),
        );
        expect(should, isFalse);

        should = await backupService.shouldAutoBackup(
          interval: const Duration(milliseconds: 1),
        );
        await Future.delayed(const Duration(milliseconds: 2));
        should = await backupService.shouldAutoBackup(
          interval: const Duration(milliseconds: 1),
        );
        expect(should, isTrue);
      });

      test('autoBackup creates backup when needed', () async {
        var backups = await backupService.listBackups();
        expect(backups.length, equals(0));

        await backupService.autoBackup();

        backups = await backupService.listBackups();
        expect(backups.length, equals(1));
      });

      test('autoBackup skips when not needed', () async {
        await backupService.createBackup();

        final result = await backupService.autoBackup();
        expect(result.isRight(), isTrue);

        final backups = await backupService.listBackups();
        expect(backups.length, equals(1)); // Still just one
      });
    });

    group('BackupInfo Model', () {
      test('should contain all required information', () async {
        await prefs.setString('test', 'data');
        await backupService.createBackup();

        final backups = await backupService.listBackups();
        final info = backups.first;

        expect(info.id, isNotEmpty);
        expect(info.timestamp, isA<DateTime>());
        expect(info.version, isNotEmpty);
        expect(info.size, greaterThan(0));
        expect(info.itemCount, greaterThan(0));
      });
    });

    group('Edge Cases', () {
      test('should handle empty preferences backup', () async {
        final result = await backupService.createBackup();
        expect(result.isRight(), isTrue);

        final backups = await backupService.listBackups();
        expect(backups.first.itemCount, greaterThanOrEqualTo(0));
      });

      test('should handle large data backup', () async {
        final largeData = 'x' * 10000;
        await prefs.setString('large_key', largeData);

        final result = await backupService.createBackup();
        expect(result.isRight(), isTrue);

        final backups = await backupService.listBackups();
        expect(backups.first.size, greaterThan(10000));
      });

      test('should handle special characters in data', () async {
        await prefs.setString('special', '{"test": "äöü 🎉"}');

        final createResult = await backupService.createBackup();
        final backupId = createResult.getOrElse(() => '');

        await prefs.remove('special');

        final restoreResult = await backupService.restoreBackup(backupId);
        expect(restoreResult.isRight(), isTrue);
        expect(prefs.getString('special'), equals('{"test": "äöü 🎉"}'));
      });
    });
  });
}
