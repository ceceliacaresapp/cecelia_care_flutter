import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your AppLocalizations. This should be the generated file.
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';

// --- I18N UPDATE ---
/// A data class to hold structured error information for localization.
class LocaleError {
  /// A key to identify the type of error, e.g., 'load_failed', 'save_failed'.
  final String type;
  /// The raw error message for debugging purposes.
  final String details;

  LocaleError({required this.type, required this.details});
}


class LocaleProvider with ChangeNotifier {
  Locale? _selectedLocale;
  static const String _selectedLanguageCodeKey = 'selected_language_code';
  bool _isInitialized = false;

  // --- I18N UPDATE ---
  // Replaced the simple String with a structured error object.
  LocaleError? _errorInfo;

  Locale? get selectedLocale => _selectedLocale;
  bool get isInitialized => _isInitialized;
  // Getter returns the new error object. The UI can use this to show a localized message.
  LocaleError? get errorInfo => _errorInfo;

  LocaleProvider() {
    _loadLocale();
  }

  void clearErrorMessage() {
    _errorInfo = null;
    notifyListeners();
  }

  Future<void> _loadLocale() async {
    _errorInfo = null; // Clear previous errors
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_selectedLanguageCodeKey);

      if (languageCode != null && languageCode.isNotEmpty) {
        final loadedLocale = Locale(languageCode);
        if (AppLocalizations.supportedLocales.any((sl) => sl.languageCode == loadedLocale.languageCode)) {
          _selectedLocale = loadedLocale;
        } else {
          debugPrint("LocaleProvider: Saved locale '$languageCode' is no longer supported. Defaulting.");
          _selectedLocale = AppLocalizations.supportedLocales.first;
        }
      } else {
        _selectedLocale = AppLocalizations.supportedLocales.first;
      }
    } catch (e) {
      debugPrint('LocaleProvider: Error loading locale from SharedPreferences: $e');
      // --- I18N UPDATE ---
      _errorInfo = LocaleError(type: 'load_failed', details: e.toString());
      _selectedLocale ??= AppLocalizations.supportedLocales.first;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    _errorInfo = null;

    if (!AppLocalizations.supportedLocales.any((sl) => sl.languageCode == newLocale.languageCode)) {
      debugPrint('Attempted to set an unsupported locale: ${newLocale.toLanguageTag()}');
      // --- I18N UPDATE ---
      _errorInfo = LocaleError(type: 'unsupported_locale', details: 'Locale ${newLocale.toLanguageTag()} is not supported.');
      notifyListeners();
      return;
    }

    if (_selectedLocale?.languageCode == newLocale.languageCode) {
      debugPrint('LocaleProvider: Locale ${newLocale.languageCode} is already set. No change.');
      return;
    }

    Locale? oldLocale = _selectedLocale;
    _selectedLocale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedLanguageCodeKey, newLocale.languageCode);
      debugPrint('LocaleProvider: Successfully set and saved locale to ${newLocale.languageCode}');
    } catch (e) {
      debugPrint("LocaleProvider: Error saving locale '${newLocale.languageCode}' to SharedPreferences: $e");
      // --- I18N UPDATE ---
      _errorInfo = LocaleError(type: 'save_failed', details: e.toString());
      _selectedLocale = oldLocale; // Revert optimistic update
      notifyListeners();
    }
  }

  Future<void> clearLocale() async {
    _errorInfo = null;
    Locale? oldLocale = _selectedLocale;
    _selectedLocale = AppLocalizations.supportedLocales.first;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedLanguageCodeKey);
      debugPrint('LocaleProvider: Successfully cleared saved locale. Reverted to default.');
    } catch (e) {
      debugPrint('LocaleProvider: Error clearing locale from SharedPreferences: $e');
      // --- I18N UPDATE ---
      _errorInfo = LocaleError(type: 'clear_failed', details: e.toString());
      _selectedLocale = oldLocale; // Revert optimistic update
      notifyListeners();
    }
  }
}