import '../../bloc/base/base_event.dart';

abstract class ThemeEvent extends BaseEvent {
  const ThemeEvent();
}

class ToggleTheme extends ThemeEvent {
  const ToggleTheme();
}

class SetLightTheme extends ThemeEvent {
  const SetLightTheme();
}

class SetDarkTheme extends ThemeEvent {
  const SetDarkTheme();
}

class SetSystemTheme extends ThemeEvent {
  const SetSystemTheme();
}
