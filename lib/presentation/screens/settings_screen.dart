import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection_container.dart' as di;
import '../../data/services/data_loading_service.dart';
import '../../data/datasources/local/database.dart';
import '../../core/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _eventCount = 0;
  int _dbVersion = 0;
  bool _notificationsEnabled = false;
  int _pendingNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
    _loadNotificationStatus();
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

      setState(() {
        _notificationsEnabled = true;
      });
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

      // Schedule 3 notifications, 10 seconds apart
      final now = DateTime.now();
      
      for (int i = 0; i < 3; i++) {
        final scheduledTime = now.add(Duration(seconds: 10 * (i + 1)));
        await notificationService.scheduleNotification(
          id: 1000 + i,
          title: 'Test Notification ${i + 1}/3',
          body: 'This is test notification ${i + 1} scheduled for ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
          scheduledTime: scheduledTime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('3 test notifications scheduled! You will receive them every 10 seconds.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
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

      setState(() {
        _notificationsEnabled = true;
      });
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
    super.dispose();
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
                  
                  // Test notification button
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
                  
                  // Schedule test notifications
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _scheduleTestNotifications,
                      icon: const Icon(Icons.schedule),
                      label: const Text('Schedule 3 Test Notifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'This will send 3 notifications every 10 seconds to test if scheduled notifications work.',
                    style: Theme.of(context).textTheme.bodySmall,
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
