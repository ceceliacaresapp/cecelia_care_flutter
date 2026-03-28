import 'package:flutter/material.dart';

/// A central place for defining the application's color palette and theme data.
class AppTheme {
  // This class is not meant to be instantiated.
  AppTheme._();

  // ---------------------------------------------------------------------------
  // PRIMARY COLORS
  // ---------------------------------------------------------------------------

  /// Primary brand color (indigo).
  static const Color primaryColor = Color(0xFF3F51B5);

  /// Accent / secondary color (deep orange). Used for CTAs and highlights.
  static const Color accentColor = Color(0xFFFF5722);

  // ---------------------------------------------------------------------------
  // TEXT COLORS
  // ---------------------------------------------------------------------------

  /// The primary text color, almost black.
  static const Color textPrimary = Color(0xFF212121);

  /// A secondary, less prominent text color.
  static const Color textSecondary = Color(0xFF757575);

  /// The lightest text color for hints and disabled text.
  static const Color textLight = Color(0xFFBDBDBD);

  /// Text color for surfaces using the primary color (e.g. buttons, app bars).
  static const Color textOnPrimary = Colors.white;

  // ---------------------------------------------------------------------------
  // SURFACE / BACKGROUND COLORS
  // ---------------------------------------------------------------------------

  /// Background color for scaffolds and main surfaces.
  static const Color backgroundColor = Colors.white;

  /// A light gray for dividers, disabled states, and input backgrounds.
  static const Color backgroundGray = Color(0xFFF5F5F5);

  // ---------------------------------------------------------------------------
  // SEMANTIC STATUS COLORS
  // ---------------------------------------------------------------------------

  /// Indicates errors or destructive actions.
  static const Color dangerColor = Color(0xFFD32F2F);

  /// Indicates warnings or cautionary states.
  static const Color warningColor = Colors.orange;

  // ---------------------------------------------------------------------------
  // ENTRY TYPE COLORS
  //
  // Each entry type has two values:
  //   - accent: the strong colour used for the left-border stripe and the
  //             title text in the timeline card.
  //   - surface: a very light tint used as the card background so the entry
  //              type is immediately recognisable at a glance.
  //
  // These are the single source of truth. The timeline card builder and any
  // other widget that colour-codes entry types should reference these rather
  // than reaching for raw Colors.xxx.shadeYYY values.
  //
  // Naming convention: entry<Type>Accent / entry<Type>Surface
  // ---------------------------------------------------------------------------

  // Message / caregiver notes
  static const Color entryMessageAccent  = accentColor;           // deep orange
  static const Color entryMessageSurface = Color(0xFFFFF3E0);     // orange 50

  // Caregiver journal
  static const Color entryCaregiverAccent  = Color(0xFF546E7A);   // blue-grey 600
  static const Color entryCaregiverSurface = Color(0xFFECEFF1);   // blue-grey 50

  // Medication
  static const Color entryMedicationAccent  = primaryColor;       // indigo
  static const Color entryMedicationSurface = Color(0xFFE8EAF6);  // indigo 50

  // Sleep
  static const Color entrySleepAccent  = Color(0xFF1565C0);       // blue 800
  static const Color entrySleepSurface = Color(0xFFE3F2FD);       // blue 50

  // Meal / food & water
  static const Color entryMealAccent  = Color(0xFF2E7D32);        // green 800
  static const Color entryMealSurface = Color(0xFFE8F5E9);        // green 50

  // Mood
  static const Color entryMoodAccent  = Color(0xFF6A1B9A);        // purple 800
  static const Color entryMoodSurface = Color(0xFFF3E5F5);        // purple 50

  // Pain
  static const Color entryPainAccent  = dangerColor;              // red
  static const Color entryPainSurface = Color(0xFFFFEBEE);        // red 50

  // Activity
  static const Color entryActivityAccent  = Color(0xFF00695C);    // teal 800
  static const Color entryActivitySurface = Color(0xFFE0F2F1);    // teal 50

  // Vital signs
  static const Color entryVitalAccent  = Color(0xFF00838F);       // cyan 800
  static const Color entryVitalSurface = Color(0xFFE0F7FA);       // cyan 50

  // Expense / financial
  static const Color entryExpenseAccent  = Color(0xFF4E342E);     // brown 800
  static const Color entryExpenseSurface = Color(0xFFEFEBE9);     // brown 50

  // Image uploads
  static const Color entryImageAccent  = Color(0xFF283593);       // indigo 800
  static const Color entryImageSurface = Color(0xFFE8EAF6);       // indigo 50

  // Fallback for unknown types
  static const Color entryDefaultAccent  = Color(0xFF546E7A);     // blue-grey 600
  static const Color entryDefaultSurface = backgroundGray;

  // ---------------------------------------------------------------------------
  // THEME DATA
  // ---------------------------------------------------------------------------

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
          color: textOnPrimary,
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
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
