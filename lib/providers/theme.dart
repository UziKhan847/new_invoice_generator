import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Three modes: light, dark (soft greys), oled (pure black for AMOLED screens)
enum AppThemeMode { light, dark, oled }

extension AppThemeModeX on AppThemeMode {
  String get label => switch (this) {
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
    AppThemeMode.oled => 'OLED Black',
  };

  IconData get icon => switch (this) {
    AppThemeMode.light => Icons.light_mode_outlined,
    AppThemeMode.dark => Icons.dark_mode_outlined,
    AppThemeMode.oled => Icons.contrast,
  };

  ThemeMode get flutterMode => switch (this) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.oled => ThemeMode.dark,
  };

  String get prefsValue => name; // 'light' | 'dark' | 'oled'
}

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _key = 'theme_mode_v2';

  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.light;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    state = switch (saved) {
      'dark' => AppThemeMode.dark,
      'oled' => AppThemeMode.oled,
      _ => AppThemeMode.light,
    };
  }

  /// Cycle through light → dark → oled → light…
  Future<void> cycle() async {
    final next = switch (state) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.oled,
      AppThemeMode.oled => AppThemeMode.light,
    };
    await set(next);
  }

  Future<void> set(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.prefsValue);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(
  ThemeNotifier.new,
);
