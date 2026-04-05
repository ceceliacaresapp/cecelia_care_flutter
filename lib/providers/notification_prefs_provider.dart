import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonEncode and jsonDecode

import '../models/notification_prefs.dart';

/// A data class to hold structured error information for localization.
class NotificationPrefsError {
  /// A key to identify the type of error, e.g., 'load_failed', 'save_failed'.
  final String type;
  /// The raw error message for debugging purposes.
  final String details;

  NotificationPrefsError({required this.type, required this.details});
}


class NotificationPrefsProvider with ChangeNotifier {
  static const String _prefsKey = 'notification_preferences';

  NotificationPrefs _prefs = NotificationPrefs.defaultPrefs();
  bool _isLoading = false;

  // Replaced the simple String with a structured error object.
  NotificationPrefsError? _errorInfo;

  NotificationPrefs get prefs => _prefs;
  bool get isLoading => _isLoading;
  // Getter returns the new error object. The UI can use this to show a localized message.
  NotificationPrefsError? get errorInfo => _errorInfo;

  static late NotificationPrefsProvider instance;

  NotificationPrefsProvider() {
    instance = this;
    _loadPrefs();
  }

  void clearErrorMessage() {
    _errorInfo = null;
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    _isLoading = true;
    _errorInfo = null;
    notifyListeners();

    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final String? prefsString = sp.getString(_prefsKey);
      if (prefsString != null) {
        _prefs = NotificationPrefs.fromJson(
          jsonDecode(prefsString) as Map<String, dynamic>,
        );
      } else {
        _prefs = NotificationPrefs.defaultPrefs();
      }
    } catch (e) {
      _errorInfo = NotificationPrefsError(type: 'load_failed', details: e.toString());
      _prefs = NotificationPrefs.defaultPrefs();
      debugPrint('Error loading notification preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _savePrefs() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setString(_prefsKey, jsonEncode(_prefs.toJson()));
      _errorInfo = null; // Clear error on successful save
    } catch (e) {
      _errorInfo = NotificationPrefsError(type: 'save_failed', details: e.toString());
      debugPrint('Error saving notification preferences: $e');
    }
    notifyListeners(); // Notify even if save fails, to update error state
  }

  Future<void> toggleMeds(bool value) async {
    if (_prefs.meds != value) {
      _prefs.meds = value;
      await _savePrefs();
    }
  }

  Future<void> toggleCalendar(bool value) async {
    if (_prefs.calendar != value) {
      _prefs.calendar = value;
      await _savePrefs();
    }
  }

  Future<void> toggleSelfCare(bool value) async {
    if (_prefs.selfCare != value) {
      _prefs.selfCare = value;
      await _savePrefs();
    }
  }

  Future<void> toggleChatMessages(bool value) async {
    if (_prefs.chatMessages != value) {
      _prefs.chatMessages = value;
      await _savePrefs();
    }
  }

  Future<void> toggleGeneralDefault(bool value) async {
    if (_prefs.generalDefault != value) {
      _prefs.generalDefault = value;
      await _savePrefs();
    }
  }
  
  Future<void> toggleHealthReminders(bool value) async {
    if (_prefs.healthReminders != value) {
      _prefs.healthReminders = value;
      await _savePrefs();
    }
  }

  Future<void> toggleSundowningAlert(bool value) async {
    if (_prefs.sundowningAlert != value) {
      _prefs.sundowningAlert = value;
      await _savePrefs();
    }
  }

  Future<void> toggleRepositioningReminder(bool value) async {
    if (_prefs.repositioningReminder != value) {
      _prefs.repositioningReminder = value;
      await _savePrefs();
    }
  }

  Future<void> toggleWeightAlerts(bool value) async {
    if (_prefs.weightAlerts != value) {
      _prefs.weightAlerts = value;
      await _savePrefs();
    }
  }

  Future<void> toggleBurnoutNudges(bool value) async {
    if (_prefs.burnoutNudges != value) {
      _prefs.burnoutNudges = value;
      await _savePrefs();
    }
  }

  /// Checks if notifications are enabled for a specific channel ID.
  Future<bool> areNotificationsEnabledForChannel(String channelId) async {
    if (_isLoading) {
      debugPrint('NotificationPrefsProvider: Checking channel $channelId while still loading.');
    }
    switch (channelId) {
      case 'med_reminders':
        return _prefs.meds;
      case 'calendar_events':
        return _prefs.calendar;
      case 'self_care':
        return _prefs.selfCare;
      case 'chat_messages':
        return _prefs.chatMessages;
      // --- FIX ---
      // This case correctly checks the 'healthReminders' preference.
      case 'health_reminders':
        return _prefs.healthReminders;
      case 'default_channel_id':
        return _prefs.generalDefault;
      default:
        debugPrint("NotificationPrefsProvider: Unknown channelId '$channelId' encountered. Defaulting to false.");
        return false;
    }
  }
}