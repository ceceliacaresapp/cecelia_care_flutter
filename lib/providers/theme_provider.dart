// lib/providers/theme_provider.dart
//
// Manages the app's theme mode (light / dark / system).
//
// Persists the user's choice in SharedPreferences so it survives app restarts.
// Exposes a ThemeMode that MaterialApp consumes via Consumer<ThemeProvider>.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider() {
    _loadFromPrefs();
  }

  static const String _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  /// The current theme mode — light, dark, or system.
  ThemeMode get themeMode => _themeMode;

  /// Human-readable label for the current mode.
  String get label {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Whether the effective theme is dark right now, accounting for system mode.
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Sets the theme mode and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _saveToPrefs();
  }

  /// Convenience setters
  Future<void> setLight() => setThemeMode(ThemeMode.light);
  Future<void> setDark() => setThemeMode(ThemeMode.dark);
  Future<void> setSystem() => setThemeMode(ThemeMode.system);

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        switch (saved) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ThemeProvider._loadFromPrefs error: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String value;
      switch (_themeMode) {
        case ThemeMode.light:
          value = 'light';
          break;
        case ThemeMode.dark:
          value = 'dark';
          break;
        case ThemeMode.system:
          value = 'system';
          break;
      }
      await prefs.setString(_prefsKey, value);
    } catch (e) {
      debugPrint('ThemeProvider._saveToPrefs error: $e');
    }
  }
}
