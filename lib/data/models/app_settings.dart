import 'package:equatable/equatable.dart';

/// Application settings model
class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final int reminderMinutesBefore;
  final bool autoSync;
  final String language;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = false,
    this.reminderMinutesBefore = 15,
    this.autoSync = true,
    this.language = 'en',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    int? reminderMinutesBefore,
    bool? autoSync,
    String? language,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      autoSync: autoSync ?? this.autoSync,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'notificationsEnabled': notificationsEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'autoSync': autoSync,
      'language': language,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 15,
      autoSync: json['autoSync'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        notificationsEnabled,
        reminderMinutesBefore,
        autoSync,
        language,
      ];
}

enum ThemeMode {
  system,
  light,
  dark,
}
