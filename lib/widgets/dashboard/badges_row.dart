// lib/widgets/dashboard/badges_row.dart
//
// Horizontal scroller of achievement badges shown on the dashboard.
// Tapping a badge opens an info dialog with progress + tier thresholds.
//
// Extracted from dashboard_screen.dart so the screen file shrinks and the
// badge UI can be reused (e.g. on the dedicated Badges screen).

import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/badge.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/confetti_overlay.dart';

class BadgesRow extends StatelessWidget {
  const BadgesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = context.watch<BadgeProvider>().badges;
    final unlocked = badges.values.where((b) => b.unlocked == true).toList();
    final locked = badges.values.where((b) => b.unlocked != true).toList();
    final all = [...unlocked, ...locked];
    if (all.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final badge = all[i];
          final isUnlocked = badge.unlocked == true;
          final accent =
              isUnlocked ? AppTheme.tileOrange : AppTheme.textLight;
          return GestureDetector(
            onTap: () => showBadgeInfoDialog(context, badge),
            child: Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppTheme.tileOrange.withValues(alpha: 0.08)
                    : AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: isUnlocked
                      ? AppTheme.tileOrange.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                    size: 20,
                    color: accent,
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      badge.label,
                      style: TextStyle(
                        fontSize: 8,
                        color: accent,
                        fontWeight: isUnlocked
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge info dialog — shown when tapping any badge (locked or unlocked)
// ---------------------------------------------------------------------------

void showBadgeInfoDialog(BuildContext context, Badge badge) {
  final isEarned = badge.tier != BadgeTier.none || badge.unlocked == true;
  final tierColor = badge.tierStyle.color;
  final thresholds = badge.thresholds;

  if (isEarned) {
    HapticUtils.celebration();
    ConfettiOverlay.trigger(context);
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      title: Row(
        children: [
          Icon(
            isEarned ? Icons.emoji_events : Icons.lock_outline,
            color: isEarned ? tierColor : AppTheme.textLight,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              badge.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isEarned ? tierColor : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            badge.description,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Current tier
          if (isEarned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: tierColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Current tier: ${badge.tierStyle.label}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tierColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Progress
          if (badge.progressLabel.isNotEmpty)
            Text(
              badge.progressLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          if (badge.progressLabel.isNotEmpty)
            const SizedBox(height: 12),

          // Tier thresholds
          if (thresholds != null) ...[
            const Text(
              'TIER REQUIREMENTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            _TierRow(
                label: 'Bronze',
                count: thresholds.bronze,
                reached: badge.progressCount >= thresholds.bronze),
            _TierRow(
                label: 'Silver',
                count: thresholds.silver,
                reached: badge.progressCount >= thresholds.silver),
            _TierRow(
                label: 'Gold',
                count: thresholds.gold,
                reached: badge.progressCount >= thresholds.gold),
            _TierRow(
                label: 'Diamond',
                count: thresholds.diamond,
                reached: badge.progressCount >= thresholds.diamond),
          ],

          const SizedBox(height: 16),

          // Why gamification matters
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.tilePurple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: AppTheme.tilePurple),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Achievements reward you for taking care of yourself '
                    'while caring for others. Small consistent actions '
                    'reduce burnout and build resilience.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.tilePurple,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.label,
    required this.count,
    required this.reached,
  });
  final String label;
  final int count;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: reached ? AppTheme.statusGreen : AppTheme.textLight,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              color: reached ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: reached ? FontWeight.w600 : FontWeight.normal,
              decoration: reached ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
