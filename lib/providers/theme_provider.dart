import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { classic, pirate }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  AppThemeMode _themeMode = AppThemeMode.pirate; // Pirate by default!
  AppThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeKey);
      if (saved != null) {
        final idx = int.tryParse(saved);
        if (idx != null && idx >= 0 && idx < AppThemeMode.values.length) {
          _themeMode = AppThemeMode.values[idx];
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _themeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode.index.toString());
    } catch (_) {}
    notifyListeners();
  }

  bool get isPirate => _themeMode == AppThemeMode.pirate;
}
