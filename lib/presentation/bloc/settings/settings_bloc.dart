import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../core/services/notification_service.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  const UpdateThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class UpdateNotificationsEnabled extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationsEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateReminderMinutes extends SettingsEvent {
  final int minutes;

  const UpdateReminderMinutes(this.minutes);

  @override
  List<Object?> get props => [minutes];
}

class UpdateAutoSync extends SettingsEvent {
  final bool enabled;

  const UpdateAutoSync(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateXCalUrl extends SettingsEvent {
  final String url;

  const UpdateXCalUrl(this.url);

  @override
  List<Object?> get props => [url];
}

// States
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;
  final NotificationService _notificationService;

  SettingsBloc(this._repository, this._notificationService)
      : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateNotificationsEnabled>(_onUpdateNotificationsEnabled);
    on<UpdateReminderMinutes>(_onUpdateReminderMinutes);
    on<UpdateAutoSync>(_onUpdateAutoSync);
    on<UpdateXCalUrl>(_onUpdateXCalUrl);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.updateThemeMode(event.themeMode);
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to update theme: $e'));
    }
  }

  Future<void> _onUpdateNotificationsEnabled(
    UpdateNotificationsEnabled event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      if (event.enabled) {
        final granted = await _notificationService.requestPermissions();
        if (!granted) {
          emit(const SettingsError('Notification permission denied'));
          return;
        }
      }

      await _repository.updateNotificationsEnabled(event.enabled);
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to update notifications: $e'));
    }
  }

  Future<void> _onUpdateReminderMinutes(
    UpdateReminderMinutes event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.updateReminderMinutes(event.minutes);
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to update reminder: $e'));
    }
  }

  Future<void> _onUpdateAutoSync(
    UpdateAutoSync event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.updateAutoSync(event.enabled);
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to update auto sync: $e'));
    }
  }

  Future<void> _onUpdateXCalUrl(
    UpdateXCalUrl event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _repository.updateXCalUrl(event.url);
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to update xCal URL: $e'));
    }
  }
}
