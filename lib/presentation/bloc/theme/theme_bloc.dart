import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/base/base_bloc.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends BaseBloc<ThemeEvent, ThemeState> {
  ThemeBloc()
      : super(const ThemeState(
          themeMode: ThemeMode.system,
          themeType: ThemeType.system,
        )) {
    on<ToggleTheme>(_onToggleTheme);
    on<SetLightTheme>(_onSetLightTheme);
    on<SetDarkTheme>(_onSetDarkTheme);
    on<SetSystemTheme>(_onSetSystemTheme);
  }

  void _onToggleTheme(ToggleTheme event, Emitter<ThemeState> emit) {
    if (state.isDark) {
      emit(const ThemeState(
        themeMode: ThemeMode.light,
        themeType: ThemeType.light,
      ));
    } else {
      emit(const ThemeState(
        themeMode: ThemeMode.dark,
        themeType: ThemeType.dark,
      ));
    }
  }

  void _onSetLightTheme(SetLightTheme event, Emitter<ThemeState> emit) {
    emit(const ThemeState(
      themeMode: ThemeMode.light,
      themeType: ThemeType.light,
    ));
  }

  void _onSetDarkTheme(SetDarkTheme event, Emitter<ThemeState> emit) {
    emit(const ThemeState(
      themeMode: ThemeMode.dark,
      themeType: ThemeType.dark,
    ));
  }

  void _onSetSystemTheme(SetSystemTheme event, Emitter<ThemeState> emit) {
    emit(const ThemeState(
      themeMode: ThemeMode.system,
      themeType: ThemeType.system,
    ));
  }
}
