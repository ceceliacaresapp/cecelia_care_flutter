// lib/screens/symptom_analytics_screen.dart
//
// Full 30-day symptom analysis with daily bar charts, trend cards,
// correlation insights, and notable events.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/providers/symptom_analytics_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class SymptomAnalyticsScreen extends StatelessWidget {
  const SymptomAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<SymptomAnalyticsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Analysis'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => analytics.refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: analytics.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !analytics.hasData
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Not enough data yet.\nLog pain, mood, or sleep entries for at least 3 days to see analysis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => analytics.refresh(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    children: [
                      // Period header
                      _PeriodHeader(daysWithData: analytics.totalDaysWithData),
                      const SizedBox(height: 20),

                      // Trend cards
                      _TrendCardsRow(
                        painAvg: analytics.overallPainAvg,
                        moodAvg: analytics.overallMoodAvg,
                        sleepAvg: analytics.overallSleepAvg,
                        trends: analytics.trends,
                      ),
                      const SizedBox(height: 24),

                      // Daily bar charts
                      if (analytics.dailyAggregates
                          .any((a) => a.painCount > 0)) ...[
                        _DailyBarChart(
                          label: 'Pain Intensity',
                          aggregates: analytics.dailyAggregates,
                          selector: (a) => a.painCount > 0 ? a.avgPain : null,
                          maxValue: 10,
                          goodColor: AppTheme.statusGreen,
                          badColor: AppTheme.statusRed,
                          invertColors: true,
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (analytics.dailyAggregates
                          .any((a) => a.moodCount > 0)) ...[
                        _DailyBarChart(
                          label: 'Mood Level',
                          aggregates: analytics.dailyAggregates,
                          selector: (a) => a.moodCount > 0 ? a.avgMood : null,
                          maxValue: 5,
                          goodColor: AppTheme.statusGreen,
                          badColor: AppTheme.statusRed,
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (analytics.dailyAggregates
                          .any((a) => a.sleepCount > 0)) ...[
                        _DailyBarChart(
                          label: 'Sleep Quality',
                          aggregates: analytics.dailyAggregates,
                          selector: (a) =>
                              a.sleepCount > 0 ? a.avgSleepQuality : null,
                          maxValue: 5,
                          goodColor: AppTheme.statusGreen,
                          badColor: AppTheme.statusRed,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Correlation insights
                      if (analytics.insights.isNotEmpty) ...[
                        const _SectionTitle(title: 'Correlations'),
                        const SizedBox(height: 10),
                        ...analytics.insights.map(
                            (insight) => _InsightCard(text: insight)),
                        const SizedBox(height: 16),
                      ],

                      // Notable events
                      if (analytics.notableEvents.isNotEmpty) ...[
                        const _SectionTitle(title: 'Notable Events'),
                        const SizedBox(height: 10),
                        ...analytics.notableEvents
                            .map((e) => _NotableEventTile(event: e)),
                        const SizedBox(height: 16),
                      ],

                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: AppTheme.textLight),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'These patterns are based on your logged data and are not medical advice. '
                                'Discuss trends with your healthcare provider.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period header
// ---------------------------------------------------------------------------
class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.daysWithData});
  final int daysWithData;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final fmt = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.entryVitalAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.entryVitalAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_outlined,
              size: 20, color: AppTheme.entryVitalAccent),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '30-Day Analysis',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.entryVitalAccent,
                ),
              ),
              Text(
                '${fmt.format(start)} – ${fmt.format(now)} · $daysWithData days with data',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.entryVitalAccent.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend cards row
// ---------------------------------------------------------------------------
class _TrendCardsRow extends StatelessWidget {
  const _TrendCardsRow({
    required this.painAvg,
    required this.moodAvg,
    required this.sleepAvg,
    required this.trends,
  });

  final double painAvg;
  final double moodAvg;
  final double sleepAvg;
  final Map<String, TrendDirection> trends;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (painAvg > 0)
          Expanded(
            child: _TrendCard(
              label: 'Pain',
              icon: Icons.healing_outlined,
              value: painAvg,
              maxLabel: '/10',
              trend: trends['pain'],
              color: AppTheme.statusRed,
            ),
          ),
        if (painAvg > 0 && moodAvg > 0) const SizedBox(width: 10),
        if (moodAvg > 0)
          Expanded(
            child: _TrendCard(
              label: 'Mood',
              icon: Icons.mood_outlined,
              value: moodAvg,
              maxLabel: '/5',
              trend: trends['mood'],
              color: AppTheme.tilePurple,
            ),
          ),
        if ((painAvg > 0 || moodAvg > 0) && sleepAvg > 0)
          const SizedBox(width: 10),
        if (sleepAvg > 0)
          Expanded(
            child: _TrendCard(
              label: 'Sleep',
              icon: Icons.bedtime_outlined,
              value: sleepAvg,
              maxLabel: '/5',
              trend: trends['sleepQuality'],
              color: AppTheme.tileIndigo,
            ),
          ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.maxLabel,
    this.trend,
    required this.color,
  });

  final String label;
  final IconData icon;
  final double value;
  final String maxLabel;
  final TrendDirection? trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    String trendText = '';
    Color trendColor = AppTheme.textSecondary;
    if (trend == TrendDirection.improving) {
      trendText = 'Improving';
      trendColor = AppTheme.statusGreen;
    } else if (trend == TrendDirection.worsening) {
      trendText = 'Worsening';
      trendColor = AppTheme.statusRed;
    } else if (trend == TrendDirection.stable) {
      trendText = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: maxLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (trendText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              trendText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily bar chart — 30 bars representing daily values
// ---------------------------------------------------------------------------
class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({
    required this.label,
    required this.aggregates,
    required this.selector,
    required this.maxValue,
    required this.goodColor,
    required this.badColor,
    this.invertColors = false,
  });

  final String label;
  final List<DailyAggregate> aggregates;
  final double? Function(DailyAggregate) selector;
  final double maxValue;
  final Color goodColor;
  final Color badColor;
  final bool invertColors; // true = high values are bad (pain)

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: label),
        const SizedBox(height: 8),
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: aggregates.map((a) {
              final val = selector(a);
              if (val == null) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              }

              final ratio = (val / maxValue).clamp(0.0, 1.0);
              final height = 8.0 + (ratio * 56); // min 8px, max 64px

              // Color: interpolate between good and bad
              final colorRatio = invertColors ? ratio : (1 - ratio);
              final barColor =
                  Color.lerp(goodColor, badColor, colorRatio) ?? goodColor;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  height: height,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Date labels
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateLabel(aggregates.first.dateString),
                style: TextStyle(fontSize: 9, color: AppTheme.textLight),
              ),
              Text(
                _formatDateLabel(aggregates.last.dateString),
                style: TextStyle(fontSize: 9, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

// ---------------------------------------------------------------------------
// Insight card
// ---------------------------------------------------------------------------
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppTheme.tileGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 16, color: AppTheme.tileOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5D4037),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notable event tile
// ---------------------------------------------------------------------------
class _NotableEventTile extends StatelessWidget {
  const _NotableEventTile({required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    Color eventColor;
    try {
      final hex = (event['color'] as String? ?? '#546E7A').replaceFirst('#', '');
      eventColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      eventColor = AppTheme.textSecondary;
    }

    String dateLabel;
    try {
      final date = DateTime.parse(event['date'] as String);
      dateLabel = DateFormat('MMM d').format(date);
    } catch (_) {
      dateLabel = event['date'] as String? ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: eventColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: eventColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined,
              size: 16, color: eventColor),
          const SizedBox(width: 8),
          Text(
            dateLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: eventColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${event['type']} — ${event['value']}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
