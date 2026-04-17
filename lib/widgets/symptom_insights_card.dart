// lib/widgets/symptom_insights_card.dart
//
// Compact dashboard card showing 30-day symptom trends and the top
// correlation insight. Tappable to open the full analytics screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/providers/symptom_analytics_provider.dart';
import 'package:cecelia_care_flutter/screens/symptom_analytics_screen.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class SymptomInsightsCard extends StatelessWidget {
  const SymptomInsightsCard({super.key});

  static const _kAccent = AppTheme.entryVitalAccent; // teal-dark

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<SymptomAnalyticsProvider>();

    if (analytics.isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!analytics.hasData || analytics.totalDaysWithData < 3) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            Icon(Icons.insights_outlined,
                size: 28, color: AppTheme.textLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                analytics.totalDaysWithData == 0
                    ? 'Log pain, mood, or sleep entries to see symptom insights'
                    : 'Keep logging — ${3 - analytics.totalDaysWithData} more day${3 - analytics.totalDaysWithData == 1 ? '' : 's'} needed for insights',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const SymptomAnalyticsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: const Icon(Icons.insights_outlined,
                      color: _kAccent, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Symptom Insights',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kAccent,
                    ),
                  ),
                ),
                Text(
                  '${analytics.totalDaysWithData} days',
                  style: TextStyle(
                    fontSize: 11,
                    color: _kAccent.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: _kAccent.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 14),

            // Trend indicators row
            Row(
              children: [
                if (analytics.overallPainAvg > 0)
                  _TrendChip(
                    label: 'Pain',
                    value: analytics.overallPainAvg,
                    maxValue: 10,
                    trend: analytics.trends['pain'],
                    invertColor: true,
                  ),
                if (analytics.overallMoodAvg > 0) ...[
                  const SizedBox(width: 10),
                  _TrendChip(
                    label: 'Mood',
                    value: analytics.overallMoodAvg,
                    maxValue: 5,
                    trend: analytics.trends['mood'],
                  ),
                ],
                if (analytics.overallSleepAvg > 0) ...[
                  const SizedBox(width: 10),
                  _TrendChip(
                    label: 'Sleep',
                    value: analytics.overallSleepAvg,
                    maxValue: 5,
                    trend: analytics.trends['sleepQuality'],
                  ),
                ],
              ],
            ),

            // Top insight
            if (analytics.insights.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InsightBox(
                icon: Icons.lightbulb_outline,
                iconColor: AppTheme.tileOrange,
                bgColor: const Color(0xFFFFF8E1),
                borderColor: AppTheme.tileGold.withValues(alpha: 0.3),
                text: analytics.insights.first,
              ),
            ],

            // Behavioral insights
            if (analytics.behavioralInsights.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final insight in analytics.behavioralInsights.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _InsightBox(
                    icon: Icons.psychology_outlined,
                    iconColor: AppTheme.tilePurple,
                    bgColor: const Color(0xFFF3E5F5),
                    borderColor: AppTheme.tilePurple.withValues(alpha: 0.2),
                    text: insight,
                    textColor: const Color(0xFF4A148C),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend chip — compact indicator for one dimension
// ---------------------------------------------------------------------------
class _TrendChip extends StatelessWidget {
  const _TrendChip({
    required this.label,
    required this.value,
    required this.maxValue,
    this.trend,
    this.invertColor = false,
  });

  final String label;
  final double value;
  final double maxValue;
  final TrendDirection? trend;
  final bool invertColor; // true for pain (lower = better)

  @override
  Widget build(BuildContext context) {
    final arrow = _arrowForTrend(trend);
    final arrowColor = _colorForTrend(trend, invertColor);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
              color: AppTheme.entryVitalAccent.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    arrow,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: arrowColor,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '/ ${maxValue.toInt()}',
              style: TextStyle(
                fontSize: 9,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _arrowForTrend(TrendDirection? t) {
    switch (t) {
      case TrendDirection.improving:
        return '↓';
      case TrendDirection.worsening:
        return '↑';
      case TrendDirection.stable:
        return '→';
      default:
        return '';
    }
  }

  Color _colorForTrend(TrendDirection? t, bool invert) {
    switch (t) {
      case TrendDirection.improving:
        return AppTheme.statusGreen;
      case TrendDirection.worsening:
        return AppTheme.statusRed;
      case TrendDirection.stable:
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _InsightBox extends StatelessWidget {
  const _InsightBox({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.text,
    this.textColor = const Color(0xFF5D4037),
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
