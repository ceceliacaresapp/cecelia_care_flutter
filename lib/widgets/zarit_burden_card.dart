// lib/widgets/zarit_burden_card.dart
//
// Self-Care tab companion to BurnoutScoreCard — shows the caregiver's
// validated ZBI-12 burden score alongside the informal 7-day burnout
// score. Designed to live directly beneath the burnout card so the
// caregiver sees both "how am I trending this week" (burnout) and
// "what's the monthly clinical picture" (Zarit) in one glance.
//
// States:
//   • No history → promotional card inviting first check-in.
//   • Has history + not due → score + delta + "view history".
//   • Has history + due (30+ days since last) → amber "time for
//     your monthly check-in" CTA, still showing the last score.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/zarit_assessment.dart';
import 'package:cecelia_care_flutter/providers/zarit_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

const Color _kAccent = AppTheme.tilePurple;

class ZaritBurdenCard extends StatelessWidget {
  const ZaritBurdenCard({
    super.key,
    required this.provider,
    required this.onStartAssessment,
    required this.onViewHistory,
  });

  final ZaritProvider provider;

  /// Opens the 12-question wizard.
  final VoidCallback onStartAssessment;

  /// Opens the trend / history screen.
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    if (!provider.hasHistory) {
      return _EmptyCard(onStart: onStartAssessment);
    }
    return _ScoreCard(
      provider: provider,
      onStart: onStartAssessment,
      onView: onViewHistory,
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — promotional
// ---------------------------------------------------------------------------

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: _kAccent.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: _kAccent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_outline,
                              color: _kAccent, size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Monthly burden check-in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXL),
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: _kAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'The Zarit Burden Interview (ZBI-12) is the clinical '
                        'gold standard for measuring caregiver strain. Social '
                        'workers and insurance companies recognize it when '
                        'approving respite.',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Take 3-minute assessment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM)),
                            minimumSize: const Size.fromHeight(40),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Populated state — score + delta + CTA
// ---------------------------------------------------------------------------

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.provider,
    required this.onStart,
    required this.onView,
  });

  final ZaritProvider provider;
  final VoidCallback onStart;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final latest = provider.latest!;
    final lvl = latest.level;
    final delta = provider.deltaFromPrevious;
    final due = provider.isDueForMonthly;
    final daysSince = provider.daysSinceLast ?? 0;
    final completedAt = latest.completedAt?.toDate();

    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        decoration: BoxDecoration(
          color: lvl.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: lvl.color.withValues(alpha: 0.22)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: lvl.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite,
                                color: lvl.color, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ZARIT BURDEN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right,
                                size: 18, color: AppTheme.textLight),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${latest.total}',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                                color: lvl.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '/ 48',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (delta != null) _DeltaChip(delta: delta),
                          ],
                        ),
                        Text(
                          lvl.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: lvl.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (completedAt != null)
                          Text(
                            'Last check-in '
                            '${DateFormat('MMM d, yyyy').format(completedAt)}'
                            ' · $daysSince '
                            '${daysSince == 1 ? 'day' : 'days'} ago',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (due)
                          _DueBanner(onStart: onStart)
                        else
                          _SubScoreStrip(assessment: latest),
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

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});
  final int delta;

  @override
  Widget build(BuildContext context) {
    // "Down" (better) is green, "up" (worse) is red — the metric is
    // burden, so lower is better.
    final bool down = delta < 0;
    final bool flat = delta == 0;
    final Color c = flat
        ? AppTheme.textSecondary
        : (down ? AppTheme.statusGreen : AppTheme.dangerColor);
    final IconData icon = flat
        ? Icons.remove
        : (down ? Icons.south : Icons.north);
    final String sign = flat ? '' : (delta > 0 ? '+' : '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: c),
            const SizedBox(width: 2),
            Text(
              '$sign$delta',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  const _DueBanner({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.statusAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
            color: AppTheme.statusAmber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined,
              size: 16, color: AppTheme.statusAmber),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Time for your monthly check-in',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onStart,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.statusAmber,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Start', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SubScoreStrip extends StatelessWidget {
  const _SubScoreStrip({required this.assessment});
  final ZaritAssessment assessment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SubBar(
            label: 'Personal',
            value: assessment.personalStrain,
            max: 24,
            color: assessment.level.color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SubBar(
            label: 'Role',
            value: assessment.roleStrain,
            max: 24,
            color: assessment.level.color,
          ),
        ),
      ],
    );
  }
}

class _SubBar extends StatelessWidget {
  const _SubBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text('$value',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
