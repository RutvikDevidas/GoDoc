import 'package:flutter/material.dart';

class AppState {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static bool get isDark => themeMode.value == ThemeMode.dark;

  static void setDark(bool enabled) {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
