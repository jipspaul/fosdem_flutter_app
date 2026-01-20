import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local/database.dart';

/// Background task name for checking upcoming events
const String taskCheckUpcomingEvents = 'checkUpcomingEvents';

/// Background task dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case taskCheckUpcomingEvents:
        await _checkAndNotifyUpcomingEvents();
        break;
    }
    return Future.value(true);
  });
}

/// Check and notify about upcoming events in user's journey
Future<void> _checkAndNotifyUpcomingEvents() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final dbPath = prefs.getString('db_path');
    if (dbPath == null) return;

    // This is a simplified version - in production, you'd need to properly
    // initialize the database in the background task
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Get the next event from journey (this would need proper database access)
    final now = DateTime.now();
    final notificationTime = now.add(const Duration(minutes: 15));

    // Show test notification
    await notificationService.showNotification(
      id: 999,
      title: 'Upcoming Event',
      body: 'You have an event starting soon!',
    );
  } catch (e) {
    print('Error in background task: $e');
  }
}

/// Service for handling local notifications (device-only)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _backgroundTasksInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle navigation based on payload
      // This could be used to navigate to a specific event
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool? granted;
    if (androidImpl != null) {
      granted = await androidImpl.requestNotificationsPermission();
    } else if (iosImpl != null) {
      granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return granted ?? false;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'fosdem_channel',
      'FOSDEM Notifications',
      channelDescription: 'Notifications for FOSDEM events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule notification for specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'fosdem_channel',
      'FOSDEM Notifications',
      channelDescription: 'Notifications for FOSDEM events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Initialize background tasks for event notifications
  Future<void> initializeBackgroundTasks() async {
    if (_backgroundTasksInitialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic task to check for upcoming events
    await Workmanager().registerPeriodicTask(
      'check-upcoming-events',
      taskCheckUpcomingEvents,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );

    _backgroundTasksInitialized = true;
  }

  /// Schedule notifications for journey events
  Future<void> scheduleJourneyNotifications({
    required List<JourneyEventData> events,
    int minutesBefore = 15,
  }) async {
    if (!_initialized) await initialize();

    // Cancel existing journey notifications
    final pending = await getPendingNotifications();
    for (final notification in pending) {
      if (notification.id >= 10000 && notification.id < 20000) {
        await cancelNotification(notification.id);
      }
    }

    // Schedule new notifications
    final now = DateTime.now();
    for (final event in events) {
      final notificationTime = event.startTime.subtract(Duration(minutes: minutesBefore));
      
      if (notificationTime.isAfter(now)) {
        await scheduleNotification(
          id: 10000 + event.eventId.hashCode % 10000,
          title: 'Event Starting Soon',
          body: '${event.title} starts in $minutesBefore minutes at ${event.room}',
          scheduledTime: notificationTime,
          payload: 'event:${event.eventId}',
        );
      }
    }
  }

  /// Cancel background tasks
  Future<void> cancelBackgroundTasks() async {
    await Workmanager().cancelAll();
    _backgroundTasksInitialized = false;
  }
}

/// Data class for journey events (used for scheduling)
class JourneyEventData {
  final int eventId;
  final String title;
  final String room;
  final DateTime startTime;

  JourneyEventData({
    required this.eventId,
    required this.title,
    required this.room,
    required this.startTime,
  });
}
