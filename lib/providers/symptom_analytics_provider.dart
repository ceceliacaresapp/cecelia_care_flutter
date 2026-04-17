// lib/providers/symptom_analytics_provider.dart
//
// Queries the last 30 days of pain/mood/sleep/activity entries,
// computes daily aggregates, trend directions, and correlation insights.
// Registered as a ChangeNotifierProxyProvider that re-computes on elder switch.

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:cecelia_care_flutter/models/behavioral_entry.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';

enum TrendDirection { improving, stable, worsening }

class DailyAggregate {
  final String dateString;
  final double avgPain;
  final double avgMood;
  final double avgSleepQuality;
  final double totalSleepHours;
  final int activityMinutes;
  final int painCount;
  final int moodCount;
  final int sleepCount;
  final int activityCount;

  const DailyAggregate({
    required this.dateString,
    this.avgPain = 0,
    this.avgMood = 0,
    this.avgSleepQuality = 0,
    this.totalSleepHours = 0,
    this.activityMinutes = 0,
    this.painCount = 0,
    this.moodCount = 0,
    this.sleepCount = 0,
    this.activityCount = 0,
  });

  bool get hasAnyData =>
      painCount > 0 || moodCount > 0 || sleepCount > 0 || activityCount > 0;
}

class SymptomAnalyticsProvider extends ChangeNotifier {
  final FirestoreService firestoreService;

  SymptomAnalyticsProvider({required this.firestoreService});

  bool _isLoading = false;
  bool _hasData = false;
  String? _currentElderId;

  List<DailyAggregate> _dailyAggregates = [];
  Map<String, TrendDirection> _trends = {};
  List<String> _insights = [];
  List<Map<String, dynamic>> _notableEvents = [];
  int _totalDaysWithData = 0;
  double _overallPainAvg = 0;
  double _overallMoodAvg = 0;
  double _overallSleepAvg = 0;

  // Behavioral pattern analysis results.
  List<String> _behavioralInsights = [];
  int _behavioralEntryCount = 0;

  // ── Getters ─────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get hasData => _hasData;
  List<DailyAggregate> get dailyAggregates => _dailyAggregates;
  Map<String, TrendDirection> get trends => _trends;
  List<String> get insights => _insights;
  List<Map<String, dynamic>> get notableEvents => _notableEvents;
  int get totalDaysWithData => _totalDaysWithData;
  double get overallPainAvg => _overallPainAvg;
  double get overallMoodAvg => _overallMoodAvg;
  double get overallSleepAvg => _overallSleepAvg;
  List<String> get behavioralInsights => _behavioralInsights;
  int get behavioralEntryCount => _behavioralEntryCount;

  void updateForElder(ElderProfile? elder) {
    final newId = elder?.id;
    if (newId == _currentElderId) return;
    _currentElderId = newId;

    if (newId == null || newId.isEmpty) {
      _reset();
      notifyListeners();
      return;
    }

    _analyze(newId);
  }

  void _reset() {
    _isLoading = false;
    _hasData = false;
    _dailyAggregates = [];
    _trends = {};
    _insights = [];
    _notableEvents = [];
    _totalDaysWithData = 0;
    _overallPainAvg = 0;
    _overallMoodAvg = 0;
    _overallSleepAvg = 0;
    _behavioralInsights = [];
    _behavioralEntryCount = 0;
  }

  Future<void> _analyze(String elderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Query all entries for the last 30 days
      final stream = firestoreService.getJournalEntriesStream(
        elderId: elderId,
        currentUserId: 'all', // We need all entries, not just visible ones
        startDate: thirtyDaysAgo,
        endDate: now,
      );

      // Take first emission only — we don't need live updates for analytics
      List<JournalEntry> entries;
      try {
        entries = await stream.first.timeout(
          const Duration(seconds: 10),
          onTimeout: () => <JournalEntry>[],
        );
      } catch (_) {
        entries = [];
      }

      if (entries.isEmpty) {
        _reset();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Filter to relevant types
      final painEntries =
          entries.where((e) => e.type == EntryType.pain).toList();
      final moodEntries =
          entries.where((e) => e.type == EntryType.mood).toList();
      final sleepEntries =
          entries.where((e) => e.type == EntryType.sleep).toList();
      final activityEntries =
          entries.where((e) => e.type == EntryType.activity).toList();

      // ── 1. Build daily aggregates ───────────────────────────────
      final Map<String, List<JournalEntry>> byDate = {};
      for (final e in [...painEntries, ...moodEntries, ...sleepEntries, ...activityEntries]) {
        byDate.putIfAbsent(e.dateString, () => []).add(e);
      }

      final aggregates = <DailyAggregate>[];
      for (int i = 0; i < 30; i++) {
        final date = thirtyDaysAgo.add(Duration(days: i));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final dayEntries = byDate[dateStr] ?? [];

        final dayPain = dayEntries.where((e) => e.type == EntryType.pain).toList();
        final dayMood = dayEntries.where((e) => e.type == EntryType.mood).toList();
        final daySleep = dayEntries.where((e) => e.type == EntryType.sleep).toList();
        final dayActivity = dayEntries.where((e) => e.type == EntryType.activity).toList();

        aggregates.add(DailyAggregate(
          dateString: dateStr,
          avgPain: _avgFromEntries(dayPain, 'intensity'),
          avgMood: _avgFromEntries(dayMood, 'moodLevel'),
          avgSleepQuality: _avgFromEntries(daySleep, 'quality'),
          totalSleepHours: _sumFromEntries(daySleep, 'totalDuration'),
          activityMinutes: _sumFromEntries(dayActivity, 'duration').toInt(),
          painCount: dayPain.length,
          moodCount: dayMood.length,
          sleepCount: daySleep.length,
          activityCount: dayActivity.length,
        ));
      }

      _dailyAggregates = aggregates;
      _totalDaysWithData = aggregates.where((a) => a.hasAnyData).length;

      // ── 2. Compute overall averages ─────────────────────────────
      final painDays = aggregates.where((a) => a.painCount > 0).toList();
      final moodDays = aggregates.where((a) => a.moodCount > 0).toList();
      final sleepDays = aggregates.where((a) => a.sleepCount > 0).toList();

      _overallPainAvg = painDays.isNotEmpty
          ? painDays.map((a) => a.avgPain).reduce((a, b) => a + b) / painDays.length
          : 0;
      _overallMoodAvg = moodDays.isNotEmpty
          ? moodDays.map((a) => a.avgMood).reduce((a, b) => a + b) / moodDays.length
          : 0;
      _overallSleepAvg = sleepDays.isNotEmpty
          ? sleepDays.map((a) => a.avgSleepQuality).reduce((a, b) => a + b) /
              sleepDays.length
          : 0;

      // ── 3. Compute trends (first half vs second half) ───────────
      _trends = {};
      if (painDays.length >= 4) {
        _trends['pain'] = _computeTrend(
          aggregates.sublist(0, 15).where((a) => a.painCount > 0),
          aggregates.sublist(15).where((a) => a.painCount > 0),
          (a) => a.avgPain,
          invertBetter: true, // lower pain = better
        );
      }
      if (moodDays.length >= 4) {
        _trends['mood'] = _computeTrend(
          aggregates.sublist(0, 15).where((a) => a.moodCount > 0),
          aggregates.sublist(15).where((a) => a.moodCount > 0),
          (a) => a.avgMood,
        );
      }
      if (sleepDays.length >= 4) {
        _trends['sleepQuality'] = _computeTrend(
          aggregates.sublist(0, 15).where((a) => a.sleepCount > 0),
          aggregates.sublist(15).where((a) => a.sleepCount > 0),
          (a) => a.avgSleepQuality,
        );
      }

      // ── 4. Detect correlations ──────────────────────────────────
      _insights = [];

      // Sleep → Pain correlation
      if (sleepDays.length >= 3 && painDays.length >= 3) {
        final poorSleepDates = aggregates
            .where((a) => a.sleepCount > 0 && a.avgSleepQuality <= 2)
            .map((a) => a.dateString)
            .toSet();

        if (poorSleepDates.isNotEmpty) {
          // Find next-day pain averages after poor sleep
          final nextDayPains = <double>[];
          for (int i = 0; i < aggregates.length - 1; i++) {
            if (poorSleepDates.contains(aggregates[i].dateString) &&
                aggregates[i + 1].painCount > 0) {
              nextDayPains.add(aggregates[i + 1].avgPain);
            }
          }
          if (nextDayPains.isNotEmpty && _overallPainAvg > 0) {
            final avgAfterPoorSleep =
                nextDayPains.reduce((a, b) => a + b) / nextDayPains.length;
            if (avgAfterPoorSleep > _overallPainAvg * 1.2) {
              _insights.add(
                'Pain tends to spike after poor sleep nights '
                '(${avgAfterPoorSleep.toStringAsFixed(1)} vs ${_overallPainAvg.toStringAsFixed(1)} avg)',
              );
            }
          }
        }
      }

      // Activity → Mood correlation
      if (moodDays.length >= 3) {
        final activeDayMoods = aggregates
            .where((a) => a.activityCount > 0 && a.moodCount > 0)
            .map((a) => a.avgMood)
            .toList();
        final inactiveDayMoods = aggregates
            .where((a) => a.activityCount == 0 && a.moodCount > 0)
            .map((a) => a.avgMood)
            .toList();

        if (activeDayMoods.isNotEmpty && inactiveDayMoods.isNotEmpty) {
          final activeAvg =
              activeDayMoods.reduce((a, b) => a + b) / activeDayMoods.length;
          final inactiveAvg =
              inactiveDayMoods.reduce((a, b) => a + b) / inactiveDayMoods.length;
          if (activeAvg > inactiveAvg * 1.15) {
            _insights.add(
              'Mood improves on active days '
              '(${activeAvg.toStringAsFixed(1)} vs ${inactiveAvg.toStringAsFixed(1)})',
            );
          }
        }
      }

      // Sleep → Mood correlation
      if (sleepDays.length >= 3 && moodDays.length >= 3) {
        final goodSleepMoods = aggregates
            .where((a) =>
                a.sleepCount > 0 && a.avgSleepQuality >= 4 && a.moodCount > 0)
            .map((a) => a.avgMood)
            .toList();
        final poorSleepMoods = aggregates
            .where((a) =>
                a.sleepCount > 0 && a.avgSleepQuality <= 2 && a.moodCount > 0)
            .map((a) => a.avgMood)
            .toList();

        if (goodSleepMoods.isNotEmpty && poorSleepMoods.isNotEmpty) {
          final goodAvg =
              goodSleepMoods.reduce((a, b) => a + b) / goodSleepMoods.length;
          final poorAvg =
              poorSleepMoods.reduce((a, b) => a + b) / poorSleepMoods.length;
          if (goodAvg > poorAvg * 1.15) {
            _insights.add(
              'Better sleep correlates with higher mood '
              '(${goodAvg.toStringAsFixed(1)} vs ${poorAvg.toStringAsFixed(1)})',
            );
          }
        }
      }

      // Pain frequency warning
      if (painDays.length > 15) {
        _insights.add(
          'Pain logged on ${painDays.length} of 30 days — consider discussing patterns with a doctor',
        );
      }

      // ── 5. Notable events ───────────────────────────────────────
      _notableEvents = [];
      for (final a in aggregates) {
        if (a.painCount > 0 && a.avgPain >= 8) {
          _notableEvents.add({
            'date': a.dateString,
            'type': 'High pain',
            'value': a.avgPain.toStringAsFixed(1),
            'color': '#E53935',
          });
        }
        if (a.moodCount > 0 && a.avgMood <= 2) {
          _notableEvents.add({
            'date': a.dateString,
            'type': 'Low mood',
            'value': a.avgMood.toStringAsFixed(1),
            'color': '#8E24AA',
          });
        }
      }

      // ── 6. Behavioral pattern detection ────────────────────────
      await _analyzeBehavioralPatterns(elderId);

      _hasData = _totalDaysWithData >= 1 || _behavioralEntryCount > 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('SymptomAnalyticsProvider._analyze error: $e');
      _reset();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _analyzeBehavioralPatterns(String elderId) async {
    _behavioralInsights = [];
    _behavioralEntryCount = 0;

    List<Map<String, dynamic>> rawEntries;
    try {
      rawEntries = await firestoreService
          .getBehavioralEntriesStream(elderId)
          .first
          .timeout(const Duration(seconds: 8), onTimeout: () => []);
    } catch (_) {
      return;
    }

    if (rawEntries.isEmpty) return;

    final entries = rawEntries
        .map((d) => BehavioralEntry.fromFirestore(d['id'] as String? ?? '', d))
        .toList();
    _behavioralEntryCount = entries.length;
    if (entries.length < 3) return; // Need a minimum sample.

    // ── Hour-of-day clustering ─────────────────────────────────
    // Group by hour to find peak agitation windows.
    final hourCounts = <int, int>{};
    final hourSeverity = <int, List<int>>{};
    for (final e in entries) {
      final parts = e.timeOfDay.split(':');
      final hour = int.tryParse(parts.firstOrNull ?? '');
      if (hour == null) continue;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      hourSeverity.putIfAbsent(hour, () => []).add(e.severity);
    }

    if (hourCounts.isNotEmpty) {
      // Find the peak 2-hour window.
      int peakStart = 0;
      int peakCount = 0;
      for (int h = 0; h < 24; h++) {
        final windowCount = (hourCounts[h] ?? 0) + (hourCounts[(h + 1) % 24] ?? 0);
        if (windowCount > peakCount) {
          peakCount = windowCount;
          peakStart = h;
        }
      }
      if (peakCount >= 2) {
        final endHour = (peakStart + 2) % 24;
        final startLabel = _formatHourLabel(peakStart);
        final endLabel = _formatHourLabel(endHour);

        // Check weekday vs weekend skew.
        int weekdayCount = 0;
        int weekendCount = 0;
        for (final e in entries) {
          final created = e.createdAt?.toDate();
          if (created == null) continue;
          final h = int.tryParse(e.timeOfDay.split(':').first);
          if (h == null) continue;
          if (h >= peakStart && h < peakStart + 2) {
            if (created.weekday >= 6) {
              weekendCount++;
            } else {
              weekdayCount++;
            }
          }
        }
        final dayQualifier = weekdayCount > weekendCount * 2
            ? ' on weekdays'
            : weekendCount > weekdayCount * 2
                ? ' on weekends'
                : '';

        _behavioralInsights.add(
          'Behavioral episodes peak $startLabel\u2013$endLabel$dayQualifier '
          '($peakCount of ${entries.length} episodes)',
        );
      }
    }

    // ── Top trigger ────────────────────────────────────────────
    final triggerCounts = <String, int>{};
    for (final e in entries) {
      final t = e.trigger;
      if (t != null && t.isNotEmpty) {
        triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
      }
    }
    if (triggerCounts.isNotEmpty) {
      final sorted = triggerCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      if (top.value >= 2) {
        final pct = (top.value / entries.length * 100).round();
        _behavioralInsights.add(
          'Top trigger: ${top.key} ($pct% of episodes)',
        );
      }
    }

    // ── De-escalation effectiveness ────────────────────────────
    // For each technique, calculate % of episodes that resolved
    // positively (outcome contains "quickly" or "gradually calmed").
    final techniqueOutcomes = <String, List<bool>>{};
    for (final e in entries) {
      final tech = e.deEscalationTechnique;
      final outcome = e.outcome;
      if (tech == null || tech.isEmpty || outcome == null) continue;
      techniqueOutcomes.putIfAbsent(tech, () => []);
      techniqueOutcomes[tech]!.add(
          outcome.contains('quickly') || outcome.contains('calmed'));
    }
    // Find the most effective technique (min 2 uses).
    String? bestTechnique;
    double bestRate = 0;
    techniqueOutcomes.forEach((tech, outcomes) {
      if (outcomes.length >= 2) {
        final positiveCount = outcomes.where((b) => b).length;
        final rate = positiveCount / outcomes.length;
        if (rate > bestRate) {
          bestRate = rate;
          bestTechnique = tech;
        }
      }
    });
    if (bestTechnique != null && bestRate > 0) {
      _behavioralInsights.add(
        'Most effective response: $bestTechnique '
        '(${(bestRate * 100).round()}% positive outcome)',
      );
    }

    // ── Severity trend ─────────────────────────────────────────
    if (entries.length >= 6) {
      final sorted = entries.toList()
        ..sort((a, b) =>
            (a.createdAt?.millisecondsSinceEpoch ?? 0)
                .compareTo(b.createdAt?.millisecondsSinceEpoch ?? 0));
      final mid = sorted.length ~/ 2;
      final firstAvg = sorted
              .sublist(0, mid)
              .map((e) => e.severity)
              .reduce((a, b) => a + b) /
          mid;
      final secondAvg = sorted
              .sublist(mid)
              .map((e) => e.severity)
              .reduce((a, b) => a + b) /
          (sorted.length - mid);
      final change = secondAvg - firstAvg;
      if (change > 0.5) {
        _behavioralInsights.add(
          'Behavioral severity trending up '
          '(${firstAvg.toStringAsFixed(1)} \u2192 ${secondAvg.toStringAsFixed(1)} avg)',
        );
      } else if (change < -0.5) {
        _behavioralInsights.add(
          'Behavioral severity improving '
          '(${firstAvg.toStringAsFixed(1)} \u2192 ${secondAvg.toStringAsFixed(1)} avg)',
        );
      }
    }
  }

  static String _formatHourLabel(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  /// Force a refresh (e.g., from pull-to-refresh on detail screen).
  void refresh() {
    if (_currentElderId != null) _analyze(_currentElderId!);
  }

  // ── Helpers ─────────────────────────────────────────────────────

  double _avgFromEntries(List<JournalEntry> entries, String key) {
    if (entries.isEmpty) return 0;
    double sum = 0;
    int count = 0;
    for (final e in entries) {
      final val = _parseNum(e.data?[key]);
      if (val != null) {
        sum += val;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  double _sumFromEntries(List<JournalEntry> entries, String key) {
    double sum = 0;
    for (final e in entries) {
      final val = _parseNum(e.data?[key]);
      if (val != null) sum += val;
    }
    return sum;
  }

  double? _parseNum(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  TrendDirection _computeTrend(
    Iterable<DailyAggregate> firstHalf,
    Iterable<DailyAggregate> secondHalf,
    double Function(DailyAggregate) selector, {
    bool invertBetter = false,
  }) {
    if (firstHalf.isEmpty || secondHalf.isEmpty) return TrendDirection.stable;

    final firstAvg =
        firstHalf.map(selector).reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg =
        secondHalf.map(selector).reduce((a, b) => a + b) / secondHalf.length;

    if (firstAvg == 0) return TrendDirection.stable;
    final change = (secondAvg - firstAvg) / firstAvg;

    if (change.abs() < 0.10) return TrendDirection.stable;

    if (invertBetter) {
      // For pain: lower = better
      return change < 0 ? TrendDirection.improving : TrendDirection.worsening;
    } else {
      // For mood/sleep: higher = better
      return change > 0 ? TrendDirection.improving : TrendDirection.worsening;
    }
  }
}
