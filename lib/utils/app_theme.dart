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
  // DARK MODE COLORS
  //
  // Suffixed with "Dark" to avoid collision with light-mode constants.
  // These are used exclusively in darkTheme below; widgets that reference
  // the static constants above (textPrimary, backgroundGray, etc.) will
  // continue working because the ThemeData's colorScheme overrides take
  // effect at the widget level via Theme.of(context).
  // ---------------------------------------------------------------------------

  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF2C2C2C);
  static const Color _darkTextPrimary = Color(0xFFE0E0E0);
  static const Color _darkTextSecondary = Color(0xFF9E9E9E);
  static const Color _darkTextLight = Color(0xFF616161);
  static const Color _darkPrimary = Color(0xFF7986CB); // lighter indigo for contrast
  static const Color _darkAccent = Color(0xFFFF8A65); // lighter deep orange

  // ---------------------------------------------------------------------------
  // SEMANTIC STATUS COLORS
  // ---------------------------------------------------------------------------

  /// Indicates errors or destructive actions.
  static const Color dangerColor = Color(0xFFD32F2F);

  // ---------------------------------------------------------------------------
  // STATUS COLORS — used for risk levels, severity, and progress indicators
  // ---------------------------------------------------------------------------

  static const Color statusGreen = Color(0xFF43A047);
  static const Color statusAmber = Color(0xFFF57C00);
  static const Color statusRed = Color(0xFFE53935);
  static const Color statusRedDeep = Color(0xFFD32F2F);

  // ---------------------------------------------------------------------------
  // TILE / FEATURE COLORS — consistent palette for Care, Settings, Dashboard
  // ---------------------------------------------------------------------------

  static const Color tileBlue = Color(0xFF1E88E5);
  static const Color tileBlueDark = Color(0xFF1565C0);
  static const Color tileIndigo = Color(0xFF5C6BC0);
  static const Color tileIndigoDark = Color(0xFF3949AB);
  static const Color tileTeal = Color(0xFF00897B);
  static const Color tileOrange = Color(0xFFF57C00);
  static const Color tileOrangeDeep = Color(0xFFE65100);
  static const Color tilePurple = Color(0xFF8E24AA);
  static const Color tileBrown = Color(0xFF795548);
  static const Color tilePink = Color(0xFFAD1457);
  static const Color tilePinkBright = Color(0xFFE91E63); // bright pink (self-care, hearts)
  static const Color tileRedDeep = Color(0xFFD84315);
  static const Color tileGold = Color(0xFFFFC107);       // amber/gold for badges
  static const Color tileIndigoDeep = Color(0xFF283593); // deep indigo (night-themed)
  static const Color tileBlueGrey = Color(0xFF546E7A);   // blue-grey 600 — secondary chrome

  // ---------------------------------------------------------------------------
  // BORDER RADIUS SCALE — use these instead of raw doubles
  // ---------------------------------------------------------------------------

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;

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
  // DARK ENTRY TYPE SURFACE COLORS
  //
  // In dark mode the pastel surfaces need to be dark-tinted versions so cards
  // are readable. Accent colors stay the same or get slightly lighter.
  // ---------------------------------------------------------------------------

  static const Color entryMessageSurfaceDark  = Color(0xFF3E2723);
  static const Color entryCaregiverSurfaceDark = Color(0xFF263238);
  static const Color entryMedicationSurfaceDark = Color(0xFF1A237E);
  static const Color entrySleepSurfaceDark    = Color(0xFF0D47A1);
  static const Color entryMealSurfaceDark     = Color(0xFF1B5E20);
  static const Color entryMoodSurfaceDark     = Color(0xFF4A148C);
  static const Color entryPainSurfaceDark     = Color(0xFF4E1313);
  static const Color entryActivitySurfaceDark = Color(0xFF004D40);
  static const Color entryVitalSurfaceDark    = Color(0xFF006064);
  static const Color entryExpenseSurfaceDark  = Color(0xFF3E2723);
  static const Color entryImageSurfaceDark    = Color(0xFF1A237E);
  static const Color entryDefaultSurfaceDark  = _darkCard;

  /// Returns the correct entry surface color based on brightness.
  /// Usage: AppTheme.entryMedicationSurfaceFor(context)
  static Color entryMessageSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryMessageSurfaceDark
          : entryMessageSurface;

  static Color entryCaregiverSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryCaregiverSurfaceDark
          : entryCaregiverSurface;

  static Color entryMedicationSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryMedicationSurfaceDark
          : entryMedicationSurface;

  static Color entrySleepSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entrySleepSurfaceDark
          : entrySleepSurface;

  static Color entryMealSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryMealSurfaceDark
          : entryMealSurface;

  static Color entryMoodSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryMoodSurfaceDark
          : entryMoodSurface;

  static Color entryPainSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryPainSurfaceDark
          : entryPainSurface;

  static Color entryActivitySurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryActivitySurfaceDark
          : entryActivitySurface;

  static Color entryVitalSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryVitalSurfaceDark
          : entryVitalSurface;

  static Color entryExpenseSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryExpenseSurfaceDark
          : entryExpenseSurface;

  static Color entryImageSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryImageSurfaceDark
          : entryImageSurface;

  static Color entryDefaultSurfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? entryDefaultSurfaceDark
          : entryDefaultSurface;

  // ---------------------------------------------------------------------------
  // THEME DATA — LIGHT
  // ---------------------------------------------------------------------------

  /// The main light theme for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
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
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        scrolledUnderElevation: 6,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textOnPrimary),
        actionsIconTheme: const IconThemeData(color: textOnPrimary),
        titleTextStyle: const TextStyle(
          color: textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        // Subtle bottom border to separate bar from content
        shape: const Border(
          bottom: BorderSide(
            color: Color(0x22000000),
            width: 1,
          ),
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

  // ---------------------------------------------------------------------------
  // THEME DATA — DARK
  // ---------------------------------------------------------------------------

  /// The dark theme for the application.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _darkPrimary,
      scaffoldBackgroundColor: _darkBackground,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkAccent,
        surface: _darkSurface,
        error: Color(0xFFEF5350), // lighter red for dark bg
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _darkTextPrimary,
        onError: Colors.white,
      ),

      // --- COMPONENT THEMES ---
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        scrolledUnderElevation: 6,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _darkTextPrimary),
        actionsIconTheme: const IconThemeData(color: _darkTextPrimary),
        titleTextStyle: const TextStyle(
          color: _darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0x33FFFFFF),
            width: 1,
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: _darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: _darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerColor: _darkTextLight,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
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
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary, width: 1.5),
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
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: _darkPrimary, width: 2.0),
        ),
        labelStyle: const TextStyle(
          color: _darkTextPrimary,
          fontFamily: 'Poppins',
        ),
        hintStyle: const TextStyle(
          color: _darkTextSecondary,
          fontFamily: 'Poppins',
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _darkPrimary,
        unselectedItemColor: _darkTextSecondary,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkPrimary;
          return _darkTextLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkPrimary.withValues(alpha: 0.4);
          }
          return _darkTextLight.withValues(alpha: 0.3);
        }),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _darkCard,
        contentTextStyle: TextStyle(
          color: _darkTextPrimary,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
