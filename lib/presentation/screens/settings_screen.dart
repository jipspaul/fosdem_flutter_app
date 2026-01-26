import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection_container.dart' as di;
import '../../data/services/data_loading_service.dart';
import '../../data/datasources/local/database.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/xcal_monitor_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _xcalUrlController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingUpdates = false;
  String? _errorMessage;
  String? _successMessage;
  int _eventCount = 0;
  int _dbVersion = 0;
  int _pendingNotifications = 0;
  DateTime? _lastCheckTime;

  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
    _loadNotificationStatus();
    _loadXCalUrl();
  }

  Future<void> _loadXCalUrl() async {
    try {
      final settingsRepository = di.sl<SettingsRepository>();
      final settings = await settingsRepository.loadSettings();
      final monitorService = di.sl<XCalMonitorService>();
      
      setState(() {
        _xcalUrlController.text = settings.xcalUrl;
        _lastCheckTime = monitorService.getLastCheckTime(settings.xcalUrl);
      });
    } catch (e) {
      print('Error loading xCal URL: $e');
    }
  }

  Future<void> _loadDatabaseStats() async {
    try {
      final database = di.sl<AppDatabase>();
      final prefs = di.sl<SharedPreferences>();
      final events = await database.select(database.events).get();
      final version = prefs.getInt('db_version') ?? 0;
      
      setState(() {
        _eventCount = events.length;
        _dbVersion = version;
      });
    } catch (e) {
      print('Error loading database stats: $e');
    }
  }

  Future<void> _loadNotificationStatus() async {
    try {
      final notificationService = NotificationService();
      final pending = await notificationService.getPendingNotifications();
      
      setState(() {
        _pendingNotifications = pending.length;
      });
    } catch (e) {
      print('Error loading notification status: $e');
    }
  }

  Future<void> _testNotification() async {
    try {
      final notificationService = NotificationService();
      
      // Request permissions first
      final granted = await notificationService.requestPermissions();
      
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permissions denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show test notification
      await notificationService.showNotification(
        id: 1,
        title: 'Test Notification',
        body: 'Notifications are working! You will receive alerts for your journey events.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scheduleTestNotifications() async {
    try {
      final notificationService = NotificationService();
      
      // Request permissions first
      final granted = await notificationService.requestPermissions();
      
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permissions denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Schedule 3 notifications with longer delays to allow app to go to background
      // First notification: 30 seconds (enough time to close app)
      // Second: 60 seconds
      // Third: 90 seconds
      final now = DateTime.now();
      
      final notifications = [
        {'delay': 30, 'title': 'Background Test 1/3', 'body': '✅ First notification - App can be closed!'},
        {'delay': 60, 'title': 'Background Test 2/3', 'body': '✅ Second notification - Still works in background!'},
        {'delay': 90, 'title': 'Background Test 3/3', 'body': '✅ Third notification - Background notifications working!'},
      ];
      
      for (int i = 0; i < notifications.length; i++) {
        final delay = notifications[i]['delay'] as int;
        final scheduledTime = now.add(Duration(seconds: delay));
        await notificationService.scheduleNotification(
          id: 1000 + i,
          title: notifications[i]['title'] as String,
          body: notifications[i]['body'] as String,
          scheduledTime: scheduledTime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('3 background test notifications scheduled! Close the app to test. First notification in 30 seconds.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
          ),
        );
      }

      // Reload pending notifications count
      await _loadNotificationStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Test background notifications by scheduling one that fires after app is closed
  Future<void> _testBackgroundNotification() async {
    try {
      final notificationService = NotificationService();
      
      // Request permissions first
      final granted = await notificationService.requestPermissions();
      
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permissions denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Schedule a notification in 20 seconds - enough time to close the app
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(seconds: 20));
      
      await notificationService.scheduleNotification(
        id: 9999,
        title: '🎉 Background Test Successful!',
        body: 'This notification fired even though the app was closed! Background notifications are working correctly.',
        scheduledTime: scheduledTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background test notification scheduled for 20 seconds. CLOSE THE APP NOW to test if it works in background!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 8),
          ),
        );
      }

      // Reload pending notifications count
      await _loadNotificationStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling background test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enableBackgroundNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initializeBackgroundTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background notifications enabled! You will be notified 15 minutes before your journey events.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling background notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _xcalUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveXCalUrl() async {
    final url = _xcalUrlController.text.trim();
    
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid xCal URL';
        _successMessage = null;
      });
      return;
    }

    // Basic URL validation
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _errorMessage = 'URL must start with http:// or https://';
        _successMessage = null;
      });
      return;
    }

    try {
      final settingsRepository = di.sl<SettingsRepository>();
      await settingsRepository.updateXCalUrl(url);
      
      setState(() {
        _successMessage = 'xCal URL saved successfully!';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save xCal URL: $e';
        _successMessage = null;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    final url = _xcalUrlController.text.trim();
    
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please configure and save an xCal URL first';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isCheckingUpdates = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final dataLoadingService = di.sl<DataLoadingService>();
      final monitorService = di.sl<XCalMonitorService>();
      
      final hasUpdated = await dataLoadingService.checkAndUpdateIfChanged(url);
      
      setState(() {
        _isCheckingUpdates = false;
        _lastCheckTime = monitorService.getLastCheckTime(url);
        
        if (hasUpdated) {
          _successMessage = 'Updates found and applied! Database has been updated.';
          _loadDatabaseStats(); // Refresh stats
        } else {
          _successMessage = 'No updates available. Your database is up to date.';
        }
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isCheckingUpdates = false;
        _errorMessage = 'Failed to check for updates: $e';
        _successMessage = null;
      });
    }
  }

  Future<void> _loadFromUrl() async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a URL';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final dataLoadingService = di.sl<DataLoadingService>();
      await dataLoadingService.loadFromUrl(url);
      
      setState(() {
        _isLoading = false;
        _successMessage = 'Data loaded successfully! Restart the app to see changes.';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
        _successMessage = null;
      });
    }
  }

  Future<void> _loadBundledData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final dataLoadingService = di.sl<DataLoadingService>();
      final prefs = di.sl<SharedPreferences>();
      
      // Clear the db_version to force reload
      await prefs.remove('db_version');
      
      await dataLoadingService.loadBundledData();
      
      // Set version after successful load
      await prefs.setInt('db_version', 5);
      
      // Reload stats
      await _loadDatabaseStats();
      
      setState(() {
        _isLoading = false;
        _successMessage = 'Bundled data reloaded successfully! Restart the app to see changes.';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load bundled data: $e';
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Data Management Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  
                  // Database info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Database Status',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text('Version: $_dbVersion'),
                        Text('Events: $_eventCount'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // xCal URL Configuration
                  const Text(
                    'xCal URL Configuration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _xcalUrlController,
                    decoration: const InputDecoration(
                      hintText: 'https://fosdem.org/2026/schedule/xcal',
                      labelText: 'xCal URL',
                      border: OutlineInputBorder(),
                      helperText: 'URL to monitor for schedule updates',
                    ),
                    enabled: !_isLoading && !_isCheckingUpdates,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || _isCheckingUpdates) ? null : _saveXCalUrl,
                          icon: const Icon(Icons.save),
                          label: const Text('Save URL'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || _isCheckingUpdates) ? null : _checkForUpdates,
                          icon: _isCheckingUpdates
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.update),
                          label: Text(_isCheckingUpdates ? 'Checking...' : 'Check for Updates'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_lastCheckTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last checked: ${_lastCheckTime!.toString().substring(0, 19)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const Divider(),
                  
                  // Reload bundled data
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Reload Bundled Data'),
                    subtitle: const Text('Reload the default xcal data'),
                    onTap: _isLoading ? null : _loadBundledData,
                  ),
                  const Divider(),
                  
                  // Load from URL
                  const Text(
                    'Load Schedule from URL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/schedule.xcal',
                      labelText: 'URL',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadFromUrl,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isLoading ? 'Loading...' : 'Load Data'),
                    ),
                  ),
                  
                  // Status messages
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notifications Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  
                  // Notification status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text('Pending Notifications: $_pendingNotifications'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Test notification button (immediate)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testNotification,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Test Notification Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Shows a notification immediately while app is open.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Test background notification (single)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testBackgroundNotification,
                      icon: const Icon(Icons.phone_android),
                      label: const Text('Test Background Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Schedules 1 notification in 20 seconds. CLOSE THE APP after tapping to test if it works when app is closed.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Schedule multiple test notifications
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _scheduleTestNotifications,
                      icon: const Icon(Icons.schedule),
                      label: const Text('Schedule 3 Background Tests'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Schedules 3 notifications (30s, 60s, 90s). CLOSE THE APP after tapping to test multiple background notifications.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Enable background notifications
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enableBackgroundNotifications,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Enable Journey Alerts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Journey alerts will notify you 15 minutes before your scheduled events, even when the app is closed.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // About Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('FOSDEM Flutter App'),
                    subtitle: const Text('Schedule viewer for FOSDEM conference'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
