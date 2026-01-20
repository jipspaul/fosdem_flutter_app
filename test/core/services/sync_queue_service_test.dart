import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fosdem_flutter/core/services/sync_queue_service.dart';
import 'package:fosdem_flutter/core/services/connectivity_service.dart';
import 'package:fosdem_flutter/data/models/sync_operation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SyncQueueService', () {
    late SyncQueueService syncQueue;
    late SharedPreferences prefs;
    late ConnectivityService connectivity;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      connectivity = ConnectivityService();
      syncQueue = SyncQueueService(prefs, connectivity);
    });

    tearDown(() async {
      await syncQueue.clear();
      syncQueue.dispose();
      connectivity.dispose();
    });

    group('Basic Operations', () {
      test('should enqueue operation', () async {
        final operation = SyncOperation(
          id: 'test-1',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.pending,
          data: {'eventId': 123},
          createdAt: DateTime.now(),
        );

        final id = await syncQueue.enqueue(operation);
        expect(id, equals('test-1'));
        expect(syncQueue.pendingCount, equals(1));
      });

      test('should get pending operations', () async {
        final op1 = SyncOperation(
          id: 'test-1',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.pending,
          data: {'eventId': 123},
          createdAt: DateTime.now(),
        );

        final op2 = SyncOperation(
          id: 'test-2',
          type: SyncOperationType.removeFavorite,
          status: SyncOperationStatus.pending,
          data: {'eventId': 456},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(op1);
        await syncQueue.enqueue(op2);

        final pending = syncQueue.getPendingOperations();
        expect(pending.length, equals(2));
      });

      test('should remove operation', () async {
        final operation = SyncOperation(
          id: 'test-remove',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.pending,
          data: {'eventId': 123},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(operation);
        expect(syncQueue.pendingCount, equals(1));

        await syncQueue.remove('test-remove');
        expect(syncQueue.pendingCount, equals(0));
      });

      test('should clear all operations', () async {
        for (int i = 0; i < 5; i++) {
          await syncQueue.enqueue(
            SyncOperation(
              id: 'test-$i',
              type: SyncOperationType.addFavorite,
              status: SyncOperationStatus.pending,
              data: {'eventId': i},
              createdAt: DateTime.now(),
            ),
          );
        }

        expect(syncQueue.pendingCount, equals(5));

        await syncQueue.clear();
        expect(syncQueue.pendingCount, equals(0));
      });
    });

    group('Priority Ordering', () {
      test('should order operations by priority', () async {
        final lowPriority = SyncOperation(
          id: 'low',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.pending,
          data: {},
          createdAt: DateTime.now(),
          priority: 1,
        );

        final highPriority = SyncOperation(
          id: 'high',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.pending,
          data: {},
          createdAt: DateTime.now(),
          priority: 10,
        );

        await syncQueue.enqueue(lowPriority);
        await syncQueue.enqueue(highPriority);

        final pending = syncQueue.getPendingOperations();
        expect(pending.first.id, equals('high'));
        expect(pending.last.id, equals('low'));
      });
    });

    group('Handler Registration', () {
      test('should register and call handler', () async {
        var handlerCalled = false;
        var receivedData = <String, dynamic>{};

        syncQueue.registerHandler(
          SyncOperationType.addFavorite,
          (op) async {
            handlerCalled = true;
            receivedData = op.data;
          },
        );

        final operation = SyncOperation(
          id: 'test-handler',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.pending,
          data: {'eventId': 999},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(operation);

        // Note: Handler execution requires connectivity and is async
        expect(handlerCalled, isFalse); // Not called yet (offline)
      });
    });

    group('Status Tracking', () {
      test('should get failed operations count', () async {
        final failed = SyncOperation(
          id: 'failed-op',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.failed,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(failed);
        expect(syncQueue.failedCount, equals(1));
      });

      test('should emit status updates', () async {
        expect(syncQueue.statusStream, emitsInOrder([
          isA<SyncQueueStatus>(),
        ]));

        final operation = SyncOperation(
          id: 'status-test',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.pending,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(operation);
      });
    });

    group('Persistence', () {
      test('should persist operations across instances', () async {
        final operation = SyncOperation(
          id: 'persist-test',
          type: SyncOperationType.addFavorite,
          status: SyncOperationStatus.pending,
          data: {'eventId': 123},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(operation);
        syncQueue.dispose();

        // Create new instance with same prefs
        final newSyncQueue = SyncQueueService(prefs, connectivity);
        expect(newSyncQueue.pendingCount, equals(1));

        newSyncQueue.dispose();
      });
    });
  });

  group('SyncOperation Model', () {
    test('should create operation with required fields', () {
      final operation = SyncOperation(
        id: 'test-id',
        type: SyncOperationType.addFavorite,
        status: SyncOperationStatus.pending,
        data: {'key': 'value'},
        createdAt: DateTime.now(),
      );

      expect(operation.id, equals('test-id'));
      expect(operation.type, equals(SyncOperationType.addFavorite));
      expect(operation.status, equals(SyncOperationStatus.pending));
    });

    test('should serialize to JSON', () {
      final now = DateTime.now();
      final operation = SyncOperation(
        id: 'json-test',
        type: SyncOperationType.removeFavorite,
        status: SyncOperationStatus.completed,
        data: {'eventId': 456},
        createdAt: now,
        priority: 5,
      );

      final json = operation.toJson();

      expect(json['id'], equals('json-test'));
      expect(json['type'], equals('removeFavorite'));
      expect(json['status'], equals('completed'));
      expect(json['priority'], equals(5));
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'deserialize-test',
        'type': 'addFavorite',
        'status': 'pending',
        'data': {'eventId': 789},
        'createdAt': DateTime.now().toIso8601String(),
        'priority': 3,
        'retryCount': 1,
        'maxRetries': 3,
      };

      final operation = SyncOperation.fromJson(json);

      expect(operation.id, equals('deserialize-test'));
      expect(operation.type, equals(SyncOperationType.addFavorite));
      expect(operation.status, equals(SyncOperationStatus.pending));
      expect(operation.priority, equals(3));
      expect(operation.retryCount, equals(1));
    });

    test('should copy with updated fields', () {
      final original = SyncOperation(
        id: 'copy-test',
        type: SyncOperationType.addFavorite,
        status: SyncOperationStatus.pending,
        data: {},
        createdAt: DateTime.now(),
      );

      final copied = original.copyWith(
        status: SyncOperationStatus.completed,
        retryCount: 2,
      );

      expect(copied.id, equals(original.id));
      expect(copied.status, equals(SyncOperationStatus.completed));
      expect(copied.retryCount, equals(2));
    });

    test('canRetry should respect max retries', () {
      final operation = SyncOperation(
        id: 'retry-test',
        type: SyncOperationType.addFavorite,
        status: SyncOperationStatus.failed,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 2,
        maxRetries: 3,
      );

      expect(operation.canRetry, isTrue);

      final maxedOut = operation.copyWith(retryCount: 3);
      expect(maxedOut.canRetry, isFalse);
    });

    test('status helper methods should work correctly', () {
      final pending = SyncOperation(
        id: 'test',
        type: SyncOperationType.addFavorite,
        status: SyncOperationStatus.pending,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(pending.isPending, isTrue);
      expect(pending.isCompleted, isFalse);
      expect(pending.isFailed, isFalse);

      final completed = pending.copyWith(status: SyncOperationStatus.completed);
      expect(completed.isCompleted, isTrue);
      expect(completed.isPending, isFalse);
    });
  });
}
