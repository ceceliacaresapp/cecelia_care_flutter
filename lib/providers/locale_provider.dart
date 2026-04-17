import 'package:flutter/material.dart';

/// Simplified locale provider — English-only for v1.0.
/// Multi-language support will be re-added in v1.1 after proper translation.
class LocaleProvider with ChangeNotifier {
  final Locale _selectedLocale = const Locale('en');

  Locale get selectedLocale => _selectedLocale;
  bool get isInitialized => true;
}
