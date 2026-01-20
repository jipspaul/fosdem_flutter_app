import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

/// Repository for managing app settings persistence
class SettingsRepository {
  static const String _settingsKey = 'app_settings';
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  /// Load settings from storage
  Future<AppSettings> loadSettings() async {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) {
      return const AppSettings();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      return const AppSettings();
    }
  }

  /// Save settings to storage
  Future<void> saveSettings(AppSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, jsonString);
  }

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode mode) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(themeMode: mode));
  }

  /// Update notifications enabled
  Future<void> updateNotificationsEnabled(bool enabled) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(notificationsEnabled: enabled));
  }

  /// Update reminder minutes before event
  Future<void> updateReminderMinutes(int minutes) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(reminderMinutesBefore: minutes));
  }

  /// Update auto sync
  Future<void> updateAutoSync(bool enabled) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(autoSync: enabled));
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    await _prefs.remove(_settingsKey);
  }
}
