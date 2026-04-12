// lib/widgets/empty_state_widget.dart
//
// Shared empty-state pattern used when a screen or section has no data.
// Replaces bare "No data" text with a consistent, encouraging layout:
//
//   [icon in soft circle]
//   Title (bold)
//   Subtitle (secondary, guiding)
//   [optional action button]
//
// All centered. Uses AppTheme colors. The action button opens the flow
// that fills the screen — turning a dead-end into a call to action.

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.color,
    this.iconSize = 48,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;
  final double iconSize;

  /// Compact mode reduces padding — use inside cards or constrained areas.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    final pad = compact ? 16.0 : 32.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 80,
              height: compact ? 56 : 80,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: c),
            ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 14 : 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
