// lib/widgets/weekly_challenge_card.dart
//
// Displays the current week's challenge with progress tracking.
//
// Shows:
//   • Challenge title + description
//   • Progress bar with current/target count
//   • Bonus points badge
//   • Completion celebration state with confetti-like visual
//   • "No challenge" state when none is active
//
// Reads from GamificationProvider — no direct Firestore access.

import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/models/weekly_challenge.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// Challenge accent — teal
const _kChallengeColor = AppTheme.tileTeal;
const _kCompletedColor = AppTheme.statusGreen;

class WeeklyChallengeCard extends StatelessWidget {
  const WeeklyChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
  });

  /// Null when no challenge is active this week.
  final ChallengeProgress? challenge;

  /// Optional tap handler for navigation to a detail screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (challenge == null) {
      return _NoChallengeCard();
    }

    final isComplete = challenge!.isComplete;
    final color = isComplete ? _kCompletedColor : _kChallengeColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header row ──────────────────────────────
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isComplete
                                    ? Icons.emoji_events
                                    : _iconForCategory(
                                        challenge!.category),
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'WEEKLY CHALLENGE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.8,
                                          color:
                                              AppTheme.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      _BonusBadge(
                                        points:
                                            challenge!.bonusPoints,
                                        earned: isComplete,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    challenge!.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ── Description ─────────────────────────────
                        Text(
                          challenge!.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Progress bar ────────────────────────────
                        _ProgressBar(
                          current: challenge!.current,
                          target: challenge!.target,
                          color: color,
                          isComplete: isComplete,
                        ),

                        // ── Completion banner ───────────────────────
                        if (isComplete) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _kCompletedColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusS),
                              border: Border.all(
                                  color: _kCompletedColor
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 16,
                                    color: _kCompletedColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Challenge complete! +${challenge!.bonusPoints} bonus pts',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kCompletedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
// Progress bar with count label
// ---------------------------------------------------------------------------
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.current,
    required this.target,
    required this.color,
    required this.isComplete,
  });
  final int current;
  final int target;
  final Color color;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isComplete ? 'Completed!' : '$current of $target',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              isComplete
                  ? '100%'
                  : '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bonus points badge — small pill showing the points reward
// ---------------------------------------------------------------------------
class _BonusBadge extends StatelessWidget {
  const _BonusBadge({required this.points, required this.earned});
  final int points;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final color = earned ? _kCompletedColor : _kChallengeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            earned ? Icons.check_circle : Icons.bolt,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '+$points pts',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No challenge state
// ---------------------------------------------------------------------------
class _NoChallengeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kChallengeColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_outlined,
                color: _kChallengeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly challenge',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'A new challenge will appear next Monday. Check in daily to stay on track!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category icon mapping
// ---------------------------------------------------------------------------
IconData _iconForCategory(ChallengeCategory category) {
  switch (category) {
    case ChallengeCategory.checkin:
      return Icons.check_circle_outline;
    case ChallengeCategory.journal:
      return Icons.menu_book_outlined;
    case ChallengeCategory.breathing:
      return Icons.air_outlined;
    case ChallengeCategory.careLog:
      return Icons.favorite_border;
    case ChallengeCategory.mixed:
      return Icons.auto_awesome_outlined;
  }
}
