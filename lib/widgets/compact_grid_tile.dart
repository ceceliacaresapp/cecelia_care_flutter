// lib/widgets/compact_grid_tile.dart
//
// Shared compact tile widgets used by Care, Settings, and Add Log screens.
// Two variants:
//   • CompactGridTile — small square for grids (icon top, title below)
//   • CompactListTile — horizontal row (icon left, title+subtitle right)
//
// Both respond physically to touch via TapScaleWrapper — a slight
// scale-down on press, bounce-back on release. Increases perceived build
// quality.

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

// ─────────────────────────────────────────────────────────────
// TapScaleWrapper — reusable press-to-shrink animation
// ─────────────────────────────────────────────────────────────

/// Wraps any child in a scale-down-on-press, bounce-back-on-release
/// animation. 100ms down to 0.95, 150ms back to 1.0 with easeOut.
///
/// Exported so other screens can use it on their own widgets without
/// reimplementing the animation.
class TapScaleWrapper extends StatefulWidget {
  const TapScaleWrapper({
    super.key,
    required this.onTap,
    required this.child,
    this.scaleDown = 0.95,
  });

  final VoidCallback onTap;
  final Widget child;
  final double scaleDown;

  @override
  State<TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<TapScaleWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _ctrl.forward();
    HapticUtils.tap();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CompactGridTile
// ─────────────────────────────────────────────────────────────

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
    return TapScaleWrapper(
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

// ─────────────────────────────────────────────────────────────
// CompactListTile
// ─────────────────────────────────────────────────────────────

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
    return TapScaleWrapper(
      onTap: onTap,
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
    );
  }
}
