import 'package:flutter/material.dart';
import '../../bloc/base/base_state.dart';

enum ThemeType { light, dark, system }

class ThemeState extends BaseState {
  final ThemeMode themeMode;
  final ThemeType themeType;
  
  const ThemeState({
    required this.themeMode,
    required this.themeType,
  });
  
  bool get isDark => themeMode == ThemeMode.dark;
  bool get isLight => themeMode == ThemeMode.light;
  bool get isSystem => themeMode == ThemeMode.system;
  
  @override
  List<Object?> get props => [themeMode, themeType];
}
