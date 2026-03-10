import 'package:flutter/material.dart';

/// A central place for defining the application's color palette and theme data.
class AppTheme {
  // This class is not meant to be instantiated.
  AppTheme._();

  // --- PRIMARY COLORS ---
  /// Primary brand color (indigo shade).
  static const Color primaryColor = Color(0xFF3F51B5);
  /// Accent / secondary color (deep orange).
  static const Color accentColor = Color(0xFFFF5722);

  // --- TEXT COLORS ---
  /// The primary text color, almost black.
  static const Color textPrimary = Color(0xFF212121); // Replaces Colors.black87
  /// A secondary, less prominent text color.
  static const Color textSecondary = Color(0xFF757575); // Replaces Colors.black54
  /// The lightest text color for hints and disabled text.
  static const Color textLight = Color(0xFFBDBDBD); // Replaces Colors.black38
  /// Text color for surfaces using the primary color (e.g., buttons, app bars).
  static const Color textOnPrimary = Colors.white;

  // --- OTHER COLORS ---
  /// Background color for scaffolds and main surfaces.
  static const Color backgroundColor = Colors.white;
  /// A light gray for dividers, disabled states, and input backgrounds.
  static const Color backgroundGray = Color(0xFFF5F5F5);
  /// A color to indicate errors or danger.
  static const Color dangerColor = Color(0xFFD32F2F);
  /// A color to indicate warnings or alerts.
  static const Color warningColor = Colors.orange;

  /// The main light theme for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        error: dangerColor,
        onPrimary: textOnPrimary,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // --- COMPONENT THEMES ---
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 1,
        iconTheme: IconThemeData(color: textOnPrimary),
        titleTextStyle: TextStyle(
          color: textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textOnPrimary, // For buttons
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide:
              const BorderSide(color: primaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
        ),
        hintStyle: const TextStyle(
          color: textSecondary,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
