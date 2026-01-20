import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/models/app_settings.dart';
import 'package:fosdem_flutter/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsRepository Tests', () {
    late SettingsRepository repository;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = SettingsRepository(prefs);
    });

    tearDown(() async {
      await prefs.clear();
    });

    test('should return default settings when none are saved', () async {
      final settings = await repository.loadSettings();
      
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.notificationsEnabled, true);
      expect(settings.reminderMinutesBefore, 15);
      expect(settings.autoSync, true);
      expect(settings.language, 'en');
    });

    test('should save and load settings correctly', () async {
      const testSettings = AppSettings(
        themeMode: ThemeMode.dark,
        notificationsEnabled: false,
        reminderMinutesBefore: 30,
        autoSync: false,
        language: 'fr',
      );

      await repository.saveSettings(testSettings);
      final loaded = await repository.loadSettings();

      expect(loaded.themeMode, ThemeMode.dark);
      expect(loaded.notificationsEnabled, false);
      expect(loaded.reminderMinutesBefore, 30);
      expect(loaded.autoSync, false);
      expect(loaded.language, 'fr');
    });

    test('should update theme mode', () async {
      await repository.updateThemeMode(ThemeMode.light);
      final settings = await repository.loadSettings();
      
      expect(settings.themeMode, ThemeMode.light);
    });

    test('should update notifications enabled', () async {
      await repository.updateNotificationsEnabled(false);
      final settings = await repository.loadSettings();
      
      expect(settings.notificationsEnabled, false);
    });

    test('should update reminder minutes', () async {
      await repository.updateReminderMinutes(60);
      final settings = await repository.loadSettings();
      
      expect(settings.reminderMinutesBefore, 60);
    });

    test('should update auto sync', () async {
      await repository.updateAutoSync(false);
      final settings = await repository.loadSettings();
      
      expect(settings.autoSync, false);
    });

    test('should clear settings', () async {
      await repository.saveSettings(const AppSettings(
        themeMode: ThemeMode.dark,
      ));
      
      await repository.clearSettings();
      final settings = await repository.loadSettings();
      
      expect(settings.themeMode, ThemeMode.system);
    });
  });

  group('AppSettings Tests', () {
    test('should create settings with default values', () {
      const settings = AppSettings();
      
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.notificationsEnabled, true);
      expect(settings.reminderMinutesBefore, 15);
      expect(settings.autoSync, true);
      expect(settings.language, 'en');
    });

    test('should create settings with custom values', () {
      const settings = AppSettings(
        themeMode: ThemeMode.dark,
        notificationsEnabled: false,
        reminderMinutesBefore: 30,
        autoSync: false,
        language: 'fr',
      );
      
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.notificationsEnabled, false);
      expect(settings.reminderMinutesBefore, 30);
      expect(settings.autoSync, false);
      expect(settings.language, 'fr');
    });

    test('should copyWith correctly', () {
      const original = AppSettings();
      final copied = original.copyWith(
        themeMode: ThemeMode.dark,
        notificationsEnabled: false,
      );
      
      expect(copied.themeMode, ThemeMode.dark);
      expect(copied.notificationsEnabled, false);
      expect(copied.reminderMinutesBefore, 15); // unchanged
      expect(copied.autoSync, true); // unchanged
    });

    test('should serialize to JSON correctly', () {
      const settings = AppSettings(
        themeMode: ThemeMode.dark,
        notificationsEnabled: false,
        reminderMinutesBefore: 30,
        autoSync: false,
        language: 'fr',
      );
      
      final json = settings.toJson();
      
      expect(json['themeMode'], 2); // ThemeMode.dark index
      expect(json['notificationsEnabled'], false);
      expect(json['reminderMinutesBefore'], 30);
      expect(json['autoSync'], false);
      expect(json['language'], 'fr');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'themeMode': 1, // ThemeMode.light
        'notificationsEnabled': false,
        'reminderMinutesBefore': 60,
        'autoSync': false,
        'language': 'de',
      };
      
      final settings = AppSettings.fromJson(json);
      
      expect(settings.themeMode, ThemeMode.light);
      expect(settings.notificationsEnabled, false);
      expect(settings.reminderMinutesBefore, 60);
      expect(settings.autoSync, false);
      expect(settings.language, 'de');
    });
  });
}
