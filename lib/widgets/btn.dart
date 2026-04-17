import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

enum BtnVariant {
  primary,
  secondary,
  danger,
  secondaryOutline,
} // Added secondaryOutline

enum BtnSize { small, medium, large }

/// A minimal “Btn” widget supporting different variants and sizes.
class Btn extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final BtnVariant variant;
  final BtnSize size;

  /// Optional padding override
  final EdgeInsets? padding;

  const Btn({
    super.key,
    required this.title,
    required this.onPressed,
    this.variant = BtnVariant.primary,
    this.size = BtnSize.medium,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Determine font size based on size
    double fontSize;
    switch (size) {
      case BtnSize.small:
        fontSize = 12;
        break;
      case BtnSize.large:
        fontSize = 18;
        break;
      case BtnSize.medium:
        fontSize = 14;
        break;
    }

    // Default padding based on size, unless overridden
    final defaultPadding = size == BtnSize.small
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : size == BtnSize.large
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);

    if (variant == BtnVariant.secondaryOutline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor, // Text color
          side: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ), // Border color and width
          padding: padding ?? defaultPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              8.0,
            ), // Consistent with AppStyles example
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight
                .w600, // Outline buttons often have slightly bolder text
          ),
        ),
      );
    } else {
      // Determine background color based on variant for ElevatedButton
      Color backgroundColor;
      Color textColor = Colors.white; // Default text color for ElevatedButton

      switch (variant) {
        case BtnVariant.secondary:
          backgroundColor = AppTheme.accentColor;
          break;
        case BtnVariant.danger:
          backgroundColor = Colors.red;
          break;
        case BtnVariant.primary:
        default:
          backgroundColor = AppTheme.primaryColor;
          break;
      }

      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding ?? defaultPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS), // Consistent shape
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}
