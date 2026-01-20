import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fosdem_flutter/core/services/cache_manager.dart';

void main() {
  group('CacheManager', () {
    late CacheManager cacheManager;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheManager = CacheManager(prefs);
    });

    tearDown(() async {
      await cacheManager.clear();
    });

    group('Basic Operations', () {
      test('should store and retrieve string value', () async {
        const key = 'test_key';
        const value = 'test_value';

        await cacheManager.set(key, value);
        final retrieved = await cacheManager.get<String>(key);

        expect(retrieved, equals(value));
      });

      test('should return null for non-existent key', () async {
        final retrieved = await cacheManager.get<String>('non_existent');
        expect(retrieved, isNull);
      });

      test('should check if key exists', () async {
        const key = 'exists_key';
        expect(await cacheManager.has(key), isFalse);

        await cacheManager.set(key, 'value');
        expect(await cacheManager.has(key), isTrue);
      });

      test('should remove cached value', () async {
        const key = 'remove_key';
        await cacheManager.set(key, 'value');
        expect(await cacheManager.has(key), isTrue);

        await cacheManager.remove(key);
        expect(await cacheManager.has(key), isFalse);
      });

      test('should clear all cache', () async {
        await cacheManager.set('key1', 'value1');
        await cacheManager.set('key2', 'value2');
        expect(cacheManager.entryCount, equals(2));

        await cacheManager.clear();
        expect(cacheManager.entryCount, equals(0));
      });
    });

    group('TTL and Expiration', () {
      test('should respect custom TTL', () async {
        const key = 'ttl_key';
        await cacheManager.set(
          key,
          'value',
          ttl: const Duration(milliseconds: 100),
        );

        expect(await cacheManager.has(key), isTrue);

        await Future.delayed(const Duration(milliseconds: 150));
        expect(await cacheManager.has(key), isFalse);
      });

      test('should clear expired entries', () async {
        await cacheManager.set('key1', 'value1', ttl: const Duration(milliseconds: 50));
        await cacheManager.set('key2', 'value2', ttl: const Duration(hours: 1));

        await Future.delayed(const Duration(milliseconds: 100));
        await cacheManager.clearExpired();

        expect(await cacheManager.has('key1'), isFalse);
        expect(await cacheManager.has('key2'), isTrue);
      });
    });

    group('Cache Size Management', () {
      test('should track cache size', () async {
        expect(cacheManager.currentSize, equals(0));

        await cacheManager.set('key1', 'small');
        expect(cacheManager.currentSize, greaterThan(0));

        final sizeAfterFirst = cacheManager.currentSize;
        await cacheManager.set('key2', 'another small value');
        expect(cacheManager.currentSize, greaterThan(sizeAfterFirst));
      });

      test('should track entry count', () async {
        expect(cacheManager.entryCount, equals(0));

        await cacheManager.set('key1', 'value1');
        expect(cacheManager.entryCount, equals(1));

        await cacheManager.set('key2', 'value2');
        expect(cacheManager.entryCount, equals(2));

        await cacheManager.remove('key1');
        expect(cacheManager.entryCount, equals(1));
      });

      test('should provide cache statistics', () {
        final stats = cacheManager.getCacheStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalSize'), isTrue);
        expect(stats.containsKey('maxSize'), isTrue);
        expect(stats.containsKey('entryCount'), isTrue);
        expect(stats.containsKey('usagePercentage'), isTrue);
      });
    });

    group('Last Sync Time', () {
      test('should store and retrieve last sync time', () async {
        final now = DateTime.now();
        await cacheManager.setLastSyncTime(now);

        final retrieved = cacheManager.getLastSyncTime();
        expect(retrieved, isNotNull);
        expect(retrieved!.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
      });

      test('should return null when no sync time set', () {
        final syncTime = cacheManager.getLastSyncTime();
        expect(syncTime, isNull);
      });
    });

    group('Edge Cases', () {
      test('should handle empty string values', () async {
        const key = 'empty_key';
        await cacheManager.set(key, '');

        final retrieved = await cacheManager.get<String>(key);
        expect(retrieved, equals(''));
      });

      test('should handle large values', () async {
        const key = 'large_key';
        final largeValue = 'x' * 1000;

        await cacheManager.set(key, largeValue);
        final retrieved = await cacheManager.get<String>(key);

        expect(retrieved, equals(largeValue));
        expect(cacheManager.currentSize, greaterThanOrEqualTo(1000));
      });

      test('should handle special characters in values', () async {
        const key = 'special_key';
        const value = '{"test": "value", "special": "chars: äöü 🎉"}';

        await cacheManager.set(key, value);
        final retrieved = await cacheManager.get<String>(key);

        expect(retrieved, equals(value));
      });
    });
  });
}
