import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/core/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    test('should be a singleton', () {
      final instance1 = NotificationService();
      final instance2 = NotificationService();
      expect(instance1, equals(instance2));
    });

    test('should initialize without errors', () async {
      expect(() => notificationService.initialize(), returnsNormally);
    });

    test('should schedule notification for future time', () async {
      await notificationService.initialize();
      final futureTime = DateTime.now().add(const Duration(minutes: 5));
      
      expect(
        () => notificationService.scheduleNotification(
          id: 1,
          title: 'Test Notification',
          body: 'This is a test notification',
          scheduledTime: futureTime,
        ),
        returnsNormally,
      );
    });

    test('should show immediate notification', () async {
      await notificationService.initialize();
      
      expect(
        () => notificationService.showNotification(
          id: 2,
          title: 'Immediate Test',
          body: 'This is an immediate notification',
        ),
        returnsNormally,
      );
    });

    test('should cancel notification', () async {
      await notificationService.initialize();
      
      expect(
        () => notificationService.cancelNotification(1),
        returnsNormally,
      );
    });

    test('should cancel all notifications', () async {
      await notificationService.initialize();
      
      expect(
        () => notificationService.cancelAllNotifications(),
        returnsNormally,
      );
    });
  });
}
