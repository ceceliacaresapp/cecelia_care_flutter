// lib/widgets/streak_widget.dart
//
// Displays the caregiver's daily check-in streak with visual flair.
//
// Shows:
//   • Flame icon that grows/glows at milestone streaks (7, 30, 90, 365)
//   • Current streak count (large, colored)
//   • "Longest: N days" subtitle
//   • Streak freeze indicator (shield icon, used/available)
//   • Level + points summary row
//
// Reads from GamificationProvider — no direct Firestore access.

import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// Accent color — warm orange for streaks
const _kStreakColor = Color(0xFFF57C00);
const _kStreakMilestoneColor = Color(0xFFE53935);
const _kFreezeColor = Color(0xFF42A5F5);

class StreakWidget extends StatelessWidget {
  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.streakFreezeAvailable,
    required this.level,
    required this.levelTitle,
    required this.totalPoints,
    required this.levelProgress,
    this.onTap,
  });

  final int currentStreak;
  final int longestStreak;
  final bool streakFreezeAvailable;
  final int level;
  final String levelTitle;
  final int totalPoints;
  final double levelProgress;

  /// Optional tap handler (e.g. navigate to a detailed stats screen).
  final VoidCallback? onTap;

  bool get _isMilestone =>
      currentStreak == 7 ||
      currentStreak == 30 ||
      currentStreak == 90 ||
      currentStreak == 365;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flameColor = _isMilestone ? _kStreakMilestoneColor : _kStreakColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kStreakColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kStreakColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: _kStreakColor.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: _kStreakColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Streak row ──────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Flame icon — larger on milestones
                            _FlameIcon(
                              color: flameColor,
                              size: _isMilestone ? 40 : 32,
                              isMilestone: _isMilestone,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline:
                                        TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$currentStreak',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: flameColor,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        currentStreak == 1
                                            ? 'day streak'
                                            : 'day streak',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: flameColor
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Longest: $longestStreak days',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Freeze indicator
                            _FreezeIndicator(
                              available: streakFreezeAvailable,
                            ),
                          ],
                        ),

                        // ── Milestone banner ────────────────────────
                        if (_isMilestone) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: flameColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: flameColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.celebration_outlined,
                                    size: 14, color: flameColor),
                                const SizedBox(width: 6),
                                Text(
                                  '$currentStreak-day milestone!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: flameColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // ── Level + points row ──────────────────────
                        Row(
                          children: [
                            // Level badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_outline,
                                      size: 14,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lv $level',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                levelTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$totalPoints pts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kStreakColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ── Level progress bar ──────────────────────
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: levelProgress.clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flame icon — custom painted for crisp rendering at any size
// ---------------------------------------------------------------------------
class _FlameIcon extends StatelessWidget {
  const _FlameIcon({
    required this.color,
    required this.size,
    required this.isMilestone,
  });
  final Color color;
  final double size;
  final bool isMilestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(isMilestone ? 0.15 : 0.08),
        border: isMilestone
            ? Border.all(color: color.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Icon(
        Icons.local_fire_department,
        size: size,
        color: color,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Freeze indicator — shield icon showing whether the weekly freeze is
// available or already used
// ---------------------------------------------------------------------------
class _FreezeIndicator extends StatelessWidget {
  const _FreezeIndicator({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: available
          ? 'Streak freeze available — miss 1 day without breaking your streak'
          : 'Streak freeze used this week',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: available
              ? _kFreezeColor.withOpacity(0.1)
              : AppTheme.backgroundGray,
        ),
        child: Icon(
          available ? Icons.shield_outlined : Icons.shield,
          size: 18,
          color: available ? _kFreezeColor : AppTheme.textLight,
        ),
      ),
    );
  }
}
