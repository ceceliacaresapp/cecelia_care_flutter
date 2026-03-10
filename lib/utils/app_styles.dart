import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class AppStyles {
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
    color: Colors.black, //FIXED
    fontFamily: 'Poppins',
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black, //FIXED
    fontFamily: 'Poppins',
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black, //FIXED
    fontFamily: 'Poppins',
  );

  static final TextStyle emptyStateText = TextStyle(
    fontSize: 16,
    color: Colors.black.withOpacity(0.6), //FIXED
    fontFamily: 'Poppins',
  );

  static const double spacingM = 16.0; //FIXED
  static const double spacingS = 8.0; //FIXED
  static const double spacingL = 24.0; //FIXED

  static const TextStyle modalTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.black, //FIXED
    fontFamily: 'Poppins',
  );

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);

  static const TextStyle listTileTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Poppins',
  );

  static const TextStyle timelineItemTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black, //FIXED
    fontFamily: 'Poppins',
  );

  static final TextStyle timelineItemMeta = TextStyle(
    fontSize: 12,
    color: Colors.black.withOpacity(0.6), //FIXED
    fontFamily: 'Poppins',
  );

  static const TextStyle timelineItemSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.black, //FIXED
    fontFamily: 'Poppins',
  );
}