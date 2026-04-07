import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class AppStyles {
  // ---------------------------------------------------------------------------
  // Text styles
  // ---------------------------------------------------------------------------

  static const TextStyle authTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryColor,
    fontFamily: 'Poppins',
  );

  static const TextStyle authErrorText = TextStyle(
    fontSize: 16,
    color: Colors.red,
    fontFamily: 'Poppins',
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: 'Poppins',
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    fontFamily: 'Poppins',
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    fontFamily: 'Poppins',
  );

  static const TextStyle emptyStateText = TextStyle(
    fontSize: 16,
    color: Color(0x99000000), // equivalent to Colors.black.withValues(alpha: 0.6)
    fontFamily: 'Poppins',
  );

  static const TextStyle modalTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: 'Poppins',
  );

  static const TextStyle listTileTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Poppins',
  );

  static const TextStyle timelineItemTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontFamily: 'Poppins',
  );

  static const TextStyle timelineItemMeta = TextStyle(
    fontSize: 12,
    color: Color(0x99000000), // equivalent to Colors.black.withValues(alpha: 0.6)
    fontFamily: 'Poppins',
  );

  static const TextStyle timelineItemSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.black,
    fontFamily: 'Poppins',
  );

  // ---------------------------------------------------------------------------
  // Spacing constants
  // ---------------------------------------------------------------------------

  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;

  // ---------------------------------------------------------------------------
  // Padding constants
  // ---------------------------------------------------------------------------

  /// Standard outer padding for full-screen pages (e.g. settings, account).
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);

  /// Padding applied to the scrollable content area inside a bottom-sheet form.
  /// Matches the horizontal gutters used in show_entry_dialog.dart.
  static const EdgeInsets formSheetPadding =
      EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 32.0);

  /// Vertical gap between two logically separate form sections (e.g.
  /// "Medication name" block → "Dose" block). Use instead of repeating
  /// SizedBox(height: 20) throughout form files.
  static const double formSectionSpacing = 20.0;

  /// Vertical gap between a section label and its input field. Use instead
  /// of repeating SizedBox(height: 8) at the start of every field group.
  static const double formFieldLabelSpacing = 8.0;

  /// Padding applied to the outer container of a form group card when a
  /// section of related inputs is visually grouped inside a Card or Container.
  static const EdgeInsets formGroupPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
}
