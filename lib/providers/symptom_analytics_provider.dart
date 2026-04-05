// lib/providers/symptom_analytics_provider.dart
//
// Queries the last 30 days of pain/mood/sleep/activity entries,
// computes daily aggregates, trend directions, and correlation insights.
// Registered as a ChangeNotifierProxyProvider that re-computes on elder switch.

import 'dart:async';
import 'package:flutter/foundation.dart';

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

      _hasData = _totalDaysWithData >= 1;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('SymptomAnalyticsProvider._analyze error: $e');
      _reset();
      _isLoading = false;
      notifyListeners();
    }
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
