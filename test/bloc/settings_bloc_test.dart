import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/features/settings/bloc/settings_bloc.dart';
import 'package:fosdem_flutter/features/settings/bloc/settings_event.dart';
import 'package:fosdem_flutter/features/settings/bloc/settings_state.dart';

void main() {
  group('SettingsBloc', () {
    blocTest<SettingsBloc, SettingsState>(
      'toggles theme mode',
      build: () => SettingsBloc(),
      act: (bloc) => bloc.add(ToggleTheme()),
      expect: () => [
        const SettingsState(isDarkMode: true),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'toggles theme mode multiple times',
      build: () => SettingsBloc(),
      act: (bloc) {
        bloc.add(ToggleTheme());
        bloc.add(ToggleTheme());
      },
      expect: () => [
        const SettingsState(isDarkMode: true),
        const SettingsState(isDarkMode: false),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'enables notifications',
      build: () => SettingsBloc(),
      act: (bloc) => bloc.add(UpdateNotifications(enabled: true)),
      expect: () => [
        const SettingsState(notificationsEnabled: true),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'disables notifications',
      build: () => SettingsBloc(),
      seed: () => const SettingsState(notificationsEnabled: true),
      act: (bloc) => bloc.add(UpdateNotifications(enabled: false)),
      expect: () => [
        const SettingsState(notificationsEnabled: false),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'updates notification lead time',
      build: () => SettingsBloc(),
      act: (bloc) => bloc.add(UpdateNotificationLeadTime(30)),
      expect: () => [
        const SettingsState(notificationLeadTime: 30),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'updates multiple settings',
      build: () => SettingsBloc(),
      act: (bloc) {
        bloc.add(ToggleTheme());
        bloc.add(UpdateNotifications(enabled: true));
        bloc.add(UpdateNotificationLeadTime(20));
      },
      expect: () => [
        const SettingsState(isDarkMode: true),
        const SettingsState(isDarkMode: true, notificationsEnabled: true),
        const SettingsState(
          isDarkMode: true,
          notificationsEnabled: true,
          notificationLeadTime: 20,
        ),
      ],
    );
  });
}
