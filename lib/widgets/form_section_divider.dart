// lib/widgets/form_section_divider.dart
//
// Subtle visual separator between form sections. Reduces cognitive load
// on dense forms by creating breathing room between groups of controls.
//
// Two widgets:
//   • FormSectionDivider — a thin line with vertical spacing
//   • FormSectionHeader — a label with a colored left accent bar

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Thin divider with vertical spacing, used between form section groups.
class FormSectionDivider extends StatelessWidget {
  const FormSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppTheme.textLight.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Section header with a colored left accent bar — makes section labels
/// visually distinct from the controls below them.
class FormSectionHeader extends StatelessWidget {
  const FormSectionHeader({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
