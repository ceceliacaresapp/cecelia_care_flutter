// lib/widgets/compact_grid_tile.dart
//
// Shared compact tile widgets used by Care, Settings, and Add Log screens.
// Two variants:
//   • CompactGridTile — small square for grids (icon top, title below)
//   • CompactListTile — horizontal row (icon left, title+subtitle right)
//
// Both use the same colored-icon-badge pattern and stay visually consistent
// with the rest of the app.

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Compact square tile used in 3-column grids (Care screen, Add Log screen).
/// Designed to be ~100px tall.
class CompactGridTile extends StatelessWidget {
  const CompactGridTile({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.showDragHandle = false,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: color,
              ),
            ),
            if (showDragHandle) ...[
              const SizedBox(height: 2),
              Icon(Icons.drag_indicator,
                  size: 12, color: color.withValues(alpha: 0.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal compact tile used in lists (Settings screen, Care reorder mode).
/// Designed to be ~64px tall.
class CompactListTile extends StatelessWidget {
  const CompactListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (showChevron)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppTheme.textLight,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
