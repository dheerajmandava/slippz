import 'package:flutter/material.dart';
import 'local_data_service.dart';

class ThemeService {
  static const String _themeKey = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  
  static ValueNotifier<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  static Future<void> initialize() async {
    final savedTheme = await LocalDataService.instance.getPreference(_themeKey);
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          _themeModeNotifier.value = ThemeMode.light;
          break;
        case 'dark':
          _themeModeNotifier.value = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeModeNotifier.value = ThemeMode.system;
          break;
      }
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    _themeModeNotifier.value = mode;
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await LocalDataService.instance.setPreference(_themeKey, modeString);
  }

  static ThemeMode getCurrentTheme() {
    return _themeModeNotifier.value;
  }
}
