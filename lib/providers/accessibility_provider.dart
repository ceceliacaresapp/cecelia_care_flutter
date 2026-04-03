// lib/providers/accessibility_provider.dart
//
// Manages the "Visual + Vibration Only" toggle and other accessibility
// preferences. Uses SharedPreferences (same pattern as ThemeProvider).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  static const String _visualOnlyKey = 'accessibility_visual_only';

  bool _visualOnlyMode = false;

  bool get isVisualOnly => _visualOnlyMode;

  AccessibilityProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    _visualOnlyMode = sp.getBool(_visualOnlyKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleVisualOnlyMode(bool value) async {
    if (_visualOnlyMode == value) return;
    _visualOnlyMode = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_visualOnlyKey, value);
    notifyListeners();
  }
}
