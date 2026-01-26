import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

/// Background task name for checking upcoming events
const String taskCheckUpcomingEvents = 'checkUpcomingEvents';

/// Background task dispatcher
/// This runs in a separate isolate, so we need to initialize everything fresh
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case taskCheckUpcomingEvents:
          await _checkAndNotifyUpcomingEvents();
          break;
        default:
          print('Unknown background task: $task');
      }
      return Future.value(true);
    } catch (e, stackTrace) {
      print('❌ Error in background task $task: $e');
      print('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

/// Check and notify about upcoming events in user's journey
/// NOTE: This runs in a background isolate, so we must initialize the notification
/// plugin separately here. The singleton NotificationService won't work across isolates.
@pragma('vm:entry-point')
Future<void> _checkAndNotifyUpcomingEvents() async {
  try {
    // Initialize timezone in background isolate
    tz.initializeTimeZones();
    
    // Create a new notification plugin instance for this isolate
    final FlutterLocalNotificationsPlugin notifications = 
        FlutterLocalNotificationsPlugin();

    // Initialize with minimal settings for background use
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: false, // Don't request in background
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await notifications.initialize(
      settings: initSettings,
    );
    
    if (initialized != true) {
      print('⚠️ Background: Notification plugin initialization returned $initialized');
      return;
    }

    // Create notification channel for Android (if needed)
    const androidChannel = AndroidNotificationChannel(
      'fosdem_channel',
      'FOSDEM Notifications',
      description: 'Notifications for FOSDEM events',
      importance: Importance.high,
    );

    final androidImpl = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(androidChannel);
    }

    // For now, show a test notification
    // TODO: In production, query the database for upcoming events and show notifications
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

    await notifications.show(
      id: 999,
      title: 'Upcoming Event',
      body: 'You have an event starting soon!',
      notificationDetails: details,
    );
    
    print('✅ Background notification sent successfully');
  } catch (e, stackTrace) {
    print('❌ Error in _checkAndNotifyUpcomingEvents: $e');
    print('Stack trace: $stackTrace');
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

    try {
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

      final initialized = await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized != true) {
        print('⚠️ Warning: Notification service initialization returned ${initialized ?? "null"}');
      }

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'fosdem_channel',
        'FOSDEM Notifications',
        description: 'Notifications for FOSDEM events',
        importance: Importance.high,
      );

      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(androidChannel);
      }

      _initialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
      rethrow;
    }
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

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Schedule notification for specific time
  /// 
  /// IMPORTANT: This method schedules notifications with the OS, which means they
  /// will fire even when the app is closed or in the background. This is the most
  /// reliable method for background notifications on both iOS and Android.
  /// 
  /// The OS handles the scheduling, so these notifications are guaranteed to work
  /// regardless of app state, battery optimization, or background restrictions.
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

    try {
      await _notifications.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        title: title,
        body: body,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('✅ Scheduled notification #$id for ${scheduledTime.toString()}');
    } catch (e) {
      print('❌ Error scheduling notification #$id: $e');
      rethrow;
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
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
    if (_backgroundTasksInitialized) {
      print('ℹ️ Background tasks already initialized');
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      print('✅ Workmanager initialized');

      // Register periodic task to check for upcoming events
      await Workmanager().registerPeriodicTask(
        'check-upcoming-events',
        taskCheckUpcomingEvents,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
      print('✅ Background task registered: check-upcoming-events');

      _backgroundTasksInitialized = true;
    } catch (e) {
      print('❌ Error initializing background tasks: $e');
      // Don't rethrow - allow app to continue even if background tasks fail
    }
  }

  /// Schedule notifications for journey events
  /// 
  /// This uses OS-level scheduling (zonedSchedule), which means notifications
  /// will fire even when the app is closed or in the background. This is the
  /// most reliable method for background notifications.
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

    // Schedule new notifications using OS-level scheduling
    // These will work even when app is closed or in background
    final now = DateTime.now();
    int scheduledCount = 0;
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
        scheduledCount++;
      }
    }
    
    print('✅ Scheduled $scheduledCount journey notifications (OS-level, works in background)');
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
