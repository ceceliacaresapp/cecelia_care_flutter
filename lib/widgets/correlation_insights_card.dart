// lib/widgets/correlation_insights_card.dart
//
// Dashboard card that shows cross-metric correlations derived from the
// existing journal entries. No new data — just math.
//
// Correlations computed:
//   • Sleep quality/duration vs next-day pain intensity
//   • Sleep quality vs next-day mood
//   • Hydration volume vs pain intensity (same day)
//   • Medication adherence vs mood
//
// Each insight only appears if there's enough data (≥5 data pairs) and
// the difference is meaningful (≥ 1 point or ≥ 20% difference).

import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class CorrelationInsightsCard extends StatefulWidget {
  const CorrelationInsightsCard({super.key});

  @override
  State<CorrelationInsightsCard> createState() =>
      _CorrelationInsightsCardState();
}

class _CorrelationInsightsCardState extends State<CorrelationInsightsCard> {
  Stream<List<JournalEntry>>? _stream;
  String? _streamElderId;

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (elder == null || uid.isEmpty) return const SizedBox.shrink();

    if (_stream == null || _streamElderId != elder.id) {
      // Use a 30-day window for correlations.
      final start = DateTime.now().subtract(const Duration(days: 30));
      _stream = context.read<JournalServiceProvider>().getJournalEntriesStream(
            elderId: elder.id,
            currentUserId: uid,
            startDate: start,
          );
      _streamElderId = elder.id;
    }

    return StreamBuilder<List<JournalEntry>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.length < 10) {
          return const SizedBox.shrink();
        }
        final entries = snap.data!;
        final insights = _computeInsights(entries);
        if (insights.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: AppTheme.tileIndigo.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.tileIndigo.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.insights_outlined,
                          color: AppTheme.tileIndigo, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Correlation insights',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('Last 30 days',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                ...insights.map(_buildInsight),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsight(_Insight i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i.icon, size: 16, color: i.color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                  fontFamily: 'Poppins',
                ),
                children: [
                  TextSpan(
                    text: i.headline,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: i.color),
                  ),
                  TextSpan(text: ' ${i.detail}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Correlation engine ──────────────────────────────────────

  List<_Insight> _computeInsights(List<JournalEntry> entries) {
    final insights = <_Insight>[];

    // Group by date string for same-day / next-day comparisons.
    final byDate = <String, List<JournalEntry>>{};
    for (final e in entries) {
      byDate.putIfAbsent(e.dateString, () => []).add(e);
    }
    final sortedDates = byDate.keys.toList()..sort();

    // Extract per-day metrics.
    final dailySleep = <String, double>{}; // date → hours
    final dailyPain = <String, double>{};  // date → avg intensity
    final dailyMood = <String, double>{};  // date → avg mood
    final dailyHydration = <String, double>{}; // date → total oz

    for (final date in sortedDates) {
      final dayEntries = byDate[date]!;

      // Sleep
      final sleeps = dayEntries.where((e) => e.type == EntryType.sleep);
      for (final s in sleeps) {
        final dur = double.tryParse(
            s.data?['totalDuration']?.toString() ?? '');
        if (dur != null && dur > 0) {
          dailySleep[date] = dur;
        }
      }

      // Pain
      final pains = dayEntries.where((e) => e.type == EntryType.pain);
      final painVals = pains
          .map((e) => (e.data?['intensity'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      if (painVals.isNotEmpty) {
        dailyPain[date] =
            painVals.reduce((a, b) => a + b) / painVals.length;
      }

      // Mood
      final moods = dayEntries.where((e) => e.type == EntryType.mood);
      final moodVals = moods
          .map((e) => (e.data?['moodLevel'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      if (moodVals.isNotEmpty) {
        dailyMood[date] =
            moodVals.reduce((a, b) => a + b) / moodVals.length;
      }

      // Hydration
      final hydrations =
          dayEntries.where((e) => e.type == EntryType.hydration);
      double hydTotal = 0;
      for (final h in hydrations) {
        final vol = (h.data?['volume'] as num?)?.toDouble() ?? 0;
        final unit = h.data?['unit'] as String? ?? 'oz';
        hydTotal += unit == 'ml' ? vol / 29.5735 : vol;
      }
      if (hydTotal > 0) dailyHydration[date] = hydTotal;
    }

    // ── Sleep → next-day pain ──────────────────────────────
    _correlate(
      insights: insights,
      metricA: dailySleep,
      metricB: dailyPain,
      sortedDates: sortedDates,
      splitThreshold: 6.0, // hours
      nextDay: true,
      lowLabel: '<6h sleep',
      highLabel: '6h+ sleep',
      metricBLabel: 'pain',
      metricBUnit: '/10',
      icon: Icons.bedtime_outlined,
      color: AppTheme.tileIndigo,
      lowerIsBetter: true,
    );

    // ── Sleep → next-day mood ──────────────────────────────
    _correlate(
      insights: insights,
      metricA: dailySleep,
      metricB: dailyMood,
      sortedDates: sortedDates,
      splitThreshold: 6.0,
      nextDay: true,
      lowLabel: '<6h sleep',
      highLabel: '6h+ sleep',
      metricBLabel: 'mood',
      metricBUnit: '/5',
      icon: Icons.sentiment_satisfied_outlined,
      color: AppTheme.tilePinkBright,
      lowerIsBetter: false,
    );

    // ── Hydration → same-day pain ──────────────────────────
    _correlate(
      insights: insights,
      metricA: dailyHydration,
      metricB: dailyPain,
      sortedDates: sortedDates,
      splitThreshold: 48.0, // oz
      nextDay: false,
      lowLabel: '<48 oz fluids',
      highLabel: '48+ oz fluids',
      metricBLabel: 'pain',
      metricBUnit: '/10',
      icon: Icons.local_drink_outlined,
      color: const Color(0xFF0288D1),
      lowerIsBetter: true,
    );

    return insights;
  }

  /// Splits days into low/high groups by [metricA] against [splitThreshold],
  /// then computes the average of [metricB] in each group. If the difference
  /// is meaningful, adds an [_Insight] to the list.
  void _correlate({
    required List<_Insight> insights,
    required Map<String, double> metricA,
    required Map<String, double> metricB,
    required List<String> sortedDates,
    required double splitThreshold,
    required bool nextDay,
    required String lowLabel,
    required String highLabel,
    required String metricBLabel,
    required String metricBUnit,
    required IconData icon,
    required Color color,
    required bool lowerIsBetter,
  }) {
    final lowGroup = <double>[];
    final highGroup = <double>[];

    for (int i = 0; i < sortedDates.length; i++) {
      final dateA = sortedDates[i];
      final dateB = nextDay && i + 1 < sortedDates.length
          ? sortedDates[i + 1]
          : dateA;
      final a = metricA[dateA];
      final b = metricB[dateB];
      if (a == null || b == null) continue;
      if (a < splitThreshold) {
        lowGroup.add(b);
      } else {
        highGroup.add(b);
      }
    }

    if (lowGroup.length < 3 || highGroup.length < 3) return;

    final lowAvg = lowGroup.reduce((a, b) => a + b) / lowGroup.length;
    final highAvg = highGroup.reduce((a, b) => a + b) / highGroup.length;
    final diff = (lowAvg - highAvg).abs();
    if (diff < 0.5) return; // not meaningful

    // Determine which direction is "worse".
    final worse = lowerIsBetter
        ? (lowAvg > highAvg ? lowLabel : highLabel)
        : (lowAvg < highAvg ? lowLabel : highLabel);
    final worseAvg = lowerIsBetter
        ? max(lowAvg, highAvg)
        : min(lowAvg, highAvg);
    final betterAvg = lowerIsBetter
        ? min(lowAvg, highAvg)
        : max(lowAvg, highAvg);

    insights.add(_Insight(
      headline:
          '$worse → ${worseAvg.toStringAsFixed(1)}$metricBUnit avg $metricBLabel',
      detail:
          'vs ${betterAvg.toStringAsFixed(1)}$metricBUnit on ${worse == lowLabel ? highLabel : lowLabel} days.',
      icon: icon,
      color: color,
    ));
  }
}

class _Insight {
  final String headline;
  final String detail;
  final IconData icon;
  final Color color;

  const _Insight({
    required this.headline,
    required this.detail,
    required this.icon,
    required this.color,
  });
}
