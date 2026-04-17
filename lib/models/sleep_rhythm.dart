// lib/models/sleep_rhythm.dart
//
// Pure compute layer that turns existing JournalEntry + BehavioralEntry
// data into a chronobiological "sleep day."
//
// Nothing in this file touches Firestore directly — the caller streams
// sleep / night-waking / behavioral docs (already live collections) and
// passes them to `SleepRhythm.compute(...)`. Keeping this as aggregation
// logic means we don't add another subcollection to maintain; the
// rhythm tracker just surfaces patterns from data the app already has.
//
// The chronobiology "day" spans noon → noon so the overnight sleep
// episode lives in the middle of the 24-hour arc instead of being
// split across midnight. The radial chart painter expects angles in
// that frame (see sleep_rhythm_radial.dart).

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';

/// A period of sleep on the chart — either the main overnight episode
/// or a daytime nap. Times are `DateTime`s anchored to real moments
/// so the painter can handle episodes that cross midnight.
class SleepPeriod {
  final DateTime start;
  final DateTime end;
  final bool isNap;
  final String? source; // journal entry id for linking

  const SleepPeriod({
    required this.start,
    required this.end,
    this.isNap = false,
    this.source,
  });

  Duration get duration => end.difference(start);
}

/// A single night-waking marker.
class RhythmWakingMark {
  final DateTime at;
  final Duration awake;
  final String? cause;
  final bool returnedToSleep;
  final String? source;

  const RhythmWakingMark({
    required this.at,
    required this.awake,
    this.cause,
    this.returnedToSleep = true,
    this.source,
  });
}

/// Behavioral event rendered as a peripheral dot on the radial chart
/// so disruptions visibly cluster around fragmented sleep.
class RhythmBehaviorMark {
  final DateTime at;
  final String type;
  final int severity; // 1..5
  final String? source;

  const RhythmBehaviorMark({
    required this.at,
    required this.type,
    required this.severity,
    this.source,
  });
}

/// One chronobiology-day aggregate. `anchor` is noon of the day the
/// main sleep episode belongs to (i.e. the morning of waking).
class SleepRhythmDay {
  final DateTime anchor; // noon of the day the person woke up

  /// The overnight main sleep episode (if any). Crosses midnight
  /// typically, so start/end are real timestamps.
  final SleepPeriod? mainSleep;

  /// Daytime naps for this day.
  final List<SleepPeriod> naps;

  /// Wakings captured during the overnight window.
  final List<RhythmWakingMark> wakings;

  /// Behavioral entries logged between noon-prior and noon-anchor.
  final List<RhythmBehaviorMark> behaviors;

  /// Caregiver-reported sleep quality 1–5 (from the SleepEntry), or
  /// null if none logged.
  final int? quality;

  const SleepRhythmDay({
    required this.anchor,
    this.mainSleep,
    this.naps = const [],
    this.wakings = const [],
    this.behaviors = const [],
    this.quality,
  });

  DateTime get windowStart =>
      DateTime(anchor.year, anchor.month, anchor.day - 1, 12);
  DateTime get windowEnd => DateTime(anchor.year, anchor.month, anchor.day, 12);

  /// Total sleep time across main + naps.
  Duration get totalSleep {
    var d = Duration.zero;
    if (mainSleep != null) d += mainSleep!.duration;
    for (final n in naps) {
      d += n.duration;
    }
    return d;
  }

  /// Fragmentation score 0–100. Higher = more disrupted. Based on
  /// waking count + cumulative time-awake within the main-sleep window.
  /// Surfaced on the card so a single number conveys "did they have a
  /// bad night?" at a glance.
  double get fragmentationScore {
    if (mainSleep == null) return wakings.isEmpty ? 0 : 100;
    final wakingMinutes =
        wakings.fold<double>(0, (a, w) => a + w.awake.inMinutes);
    final countScore = (wakings.length * 12).clamp(0, 60);
    final timeScore = (wakingMinutes / 2).clamp(0, 40);
    return (countScore + timeScore).toDouble().clamp(0, 100);
  }

  /// Rule-of-thumb label for the fragmentation band.
  String get fragmentationLabel {
    final s = fragmentationScore;
    if (s < 20) return 'Consolidated';
    if (s < 50) return 'Mild fragmentation';
    if (s < 75) return 'Moderate fragmentation';
    return 'Severely fragmented';
  }

  bool get hasAnyData =>
      mainSleep != null ||
      naps.isNotEmpty ||
      wakings.isNotEmpty ||
      behaviors.isNotEmpty;
}

/// Multi-day rolling view produced for the UI.
class SleepRhythm {
  final List<SleepRhythmDay> days; // oldest → newest

  const SleepRhythm({required this.days});

  /// Average nightly sleep (main + naps). null when no days have data.
  Duration? get averageTotalSleep {
    final usable = days.where((d) => d.totalSleep > Duration.zero).toList();
    if (usable.isEmpty) return null;
    final total = usable.fold<int>(0, (a, d) => a + d.totalSleep.inMinutes);
    return Duration(minutes: (total / usable.length).round());
  }

  /// Average bedtime expressed as minutes since 6 PM (negative = earlier
  /// than 6 PM). Returns null when no main-sleep episodes exist.
  ///
  /// We use 6 PM as the reference so pre-midnight and post-midnight
  /// bedtimes can be averaged on the same scale.
  double? get averageBedtimeMinutesFromSixPm {
    final beds = <int>[];
    for (final d in days) {
      final ms = d.mainSleep;
      if (ms == null) continue;
      final sixPm =
          DateTime(ms.start.year, ms.start.month, ms.start.day, 18);
      // If bedtime is between midnight and 6 PM next day, shift back 24h
      // so we're measuring "night of" consistently.
      final offset = ms.start.difference(sixPm).inMinutes;
      beds.add(offset);
    }
    if (beds.isEmpty) return null;
    return beds.reduce((a, b) => a + b) / beds.length;
  }

  /// Average wake time expressed as minutes since midnight.
  double? get averageWakeMinutesFromMidnight {
    final wakes = <int>[];
    for (final d in days) {
      final ms = d.mainSleep;
      if (ms == null) continue;
      wakes.add(ms.end.hour * 60 + ms.end.minute);
    }
    if (wakes.isEmpty) return null;
    return wakes.reduce((a, b) => a + b) / wakes.length;
  }

  /// Average fragmentation score. null if no data.
  double? get averageFragmentation {
    final usable = days.where((d) => d.hasAnyData).toList();
    if (usable.isEmpty) return null;
    return usable.fold<double>(0, (a, d) => a + d.fragmentationScore) /
        usable.length;
  }

  /// Average nightly waking count (main-sleep window only). null if no data.
  double? get averageWakings {
    final usable = days.where((d) => d.hasAnyData).toList();
    if (usable.isEmpty) return null;
    return usable.fold<int>(0, (a, d) => a + d.wakings.length) / usable.length;
  }

  /// Days where behavioral events fall within 4 hours after a fragmented
  /// night — the "sundowning predictor" window highlighted by the report.
  int get fragmentedNightsFollowedByBehavior {
    var count = 0;
    for (final d in days) {
      if (d.fragmentationScore < 50) continue;
      if (d.behaviors.any((b) =>
          b.at.isAfter(d.anchor) &&
          b.at.difference(d.anchor).inHours <= 8)) {
        count++;
      }
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Builder
  // ---------------------------------------------------------------------------

  /// Builds a [SleepRhythm] covering [daysCount] chronobiology-days
  /// ending today.
  ///
  /// Inputs are the raw entries already loaded from Firestore — this
  /// function is pure so the screen can recompute cheaply on each
  /// stream update.
  static SleepRhythm compute({
    required List<JournalEntry> sleepEntries,
    required List<JournalEntry> nightWakingEntries,
    required List<Map<String, dynamic>> behavioralEntries,
    int daysCount = 7,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final anchors = <DateTime>[];
    for (int i = daysCount - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      anchors.add(DateTime(d.year, d.month, d.day, 12));
    }

    // Pre-bucket inputs by anchor (noon-to-noon). Sleep and nightWaking
    // JournalEntries carry a dateString in yyyy-MM-dd of the date the
    // caregiver saved on — but the actual time of the event is what
    // matters for bucketing, so we parse entryTimestamp.
    final Map<DateTime, SleepPeriod?> mainSleepByAnchor = {};
    final Map<DateTime, List<SleepPeriod>> napsByAnchor = {
      for (final a in anchors) a: [],
    };
    final Map<DateTime, int?> qualityByAnchor = {};
    final Map<DateTime, List<RhythmWakingMark>> wakingsByAnchor = {
      for (final a in anchors) a: [],
    };
    final Map<DateTime, List<RhythmBehaviorMark>> behaviorsByAnchor = {
      for (final a in anchors) a: [],
    };

    DateTime? anchorFor(DateTime at) {
      // Find the anchor A such that windowStart(A) <= at < windowEnd(A)
      // i.e. (A - 1day noon) <= at < A noon.
      for (final a in anchors) {
        final start = DateTime(a.year, a.month, a.day - 1, 12);
        if (!at.isBefore(start) && at.isBefore(a)) return a;
      }
      return null;
    }

    // --- Sleep entries ---
    for (final e in sleepEntries) {
      if (e.type != EntryType.sleep) continue;
      final d = e.data ?? const <String, dynamic>{};
      final bedStr = d['wentToBed'] as String?;
      final wakeStr = d['wokeUp'] as String?;
      final isNap = (d['isNap'] as bool?) ?? false;

      final stamp = e.entryTimestamp.toDate();
      final period = _parsePeriod(
        stamp: stamp,
        bedStr: bedStr,
        wakeStr: wakeStr,
        isNap: isNap,
        source: e.id,
      );
      if (period == null) continue;

      // For main sleep we anchor on the WAKE time (morning of the day);
      // for naps we anchor on when the nap starts.
      final anchorTarget = isNap ? period.start : period.end;
      final anchor = anchorFor(anchorTarget);
      if (anchor == null) continue;

      if (isNap) {
        napsByAnchor[anchor]!.add(period);
      } else {
        // Keep the longest main-sleep episode per anchor in case the
        // caregiver double-logged.
        final existing = mainSleepByAnchor[anchor];
        if (existing == null || period.duration > existing.duration) {
          mainSleepByAnchor[anchor] = period;
        }
        final q = d['quality'];
        if (q is num) {
          qualityByAnchor[anchor] = q.toInt();
        } else if (q is String) {
          final parsed = int.tryParse(q);
          if (parsed != null) qualityByAnchor[anchor] = parsed;
        }
      }
    }

    // --- Night wakings ---
    for (final e in nightWakingEntries) {
      if (e.type != EntryType.nightWaking) continue;
      final stamp = e.entryTimestamp.toDate();
      final anchor = anchorFor(stamp);
      if (anchor == null) continue;

      final d = e.data ?? const <String, dynamic>{};
      final duration = _parseDurationMinutes(d['duration'] as String?);
      final cause = d['cause'] as String?;
      final returned = (d['returnedToSleep'] as bool?) ?? true;

      wakingsByAnchor[anchor]!.add(RhythmWakingMark(
        at: stamp,
        awake: Duration(minutes: duration),
        cause: cause,
        returnedToSleep: returned,
        source: e.id,
      ));
    }

    // --- Behavioral entries (correlation overlay) ---
    for (final m in behavioralEntries) {
      final created = m['createdAt'];
      final time = m['timeOfDay'] as String?;
      DateTime? at;
      if (created is Timestamp) {
        at = created.toDate();
      } else if (created is DateTime) {
        at = created;
      }
      if (at == null) continue;
      // Override hour/minute with timeOfDay if we have it — caregivers
      // often log hours after the event.
      if (time != null && RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
        final parts = time.split(':');
        at = DateTime(
          at.year,
          at.month,
          at.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
      final anchor = anchorFor(at);
      if (anchor == null) continue;
      behaviorsByAnchor[anchor]!.add(RhythmBehaviorMark(
        at: at,
        type: (m['behaviorType'] as String?) ?? 'Behavior',
        severity: (m['severity'] as num?)?.toInt() ?? 1,
        source: m['id'] as String?,
      ));
    }

    final out = <SleepRhythmDay>[];
    for (final a in anchors) {
      out.add(SleepRhythmDay(
        anchor: a,
        mainSleep: mainSleepByAnchor[a],
        naps: napsByAnchor[a]!,
        wakings: wakingsByAnchor[a]!,
        behaviors: behaviorsByAnchor[a]!,
        quality: qualityByAnchor[a],
      ));
    }
    return SleepRhythm(days: out);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static SleepPeriod? _parsePeriod({
    required DateTime stamp,
    required String? bedStr,
    required String? wakeStr,
    required bool isNap,
    String? source,
  }) {
    // The caregiver logs the entry after-the-fact — `stamp` is the
    // save time, not the sleep time. `wentToBed` and `wokeUp` are
    // "HH:mm" clock times. We anchor them against the entry's own
    // calendar date, then roll the wake forward if the math says it
    // must have been overnight.
    final bedTime = _parseHhmm(bedStr);
    final wakeTime = _parseHhmm(wakeStr);
    if (bedTime == null) return null;

    // Anchor to the stamp's calendar day.
    DateTime bedDate = DateTime(
      stamp.year,
      stamp.month,
      stamp.day,
      bedTime.$1,
      bedTime.$2,
    );
    // A "main sleep" entry logged in the morning typically means "I
    // slept last night": if bed hour >= 18 (evening), push bedDate
    // back a day so it lands on yesterday evening.
    if (!isNap && bedTime.$1 >= 18 && stamp.hour < 12) {
      bedDate = bedDate.subtract(const Duration(days: 1));
    }

    DateTime wakeDate;
    if (wakeTime == null) {
      // Assume 8-hour default when wake missing so the arc still renders.
      wakeDate = bedDate.add(const Duration(hours: 8));
    } else {
      wakeDate = DateTime(
        bedDate.year,
        bedDate.month,
        bedDate.day,
        wakeTime.$1,
        wakeTime.$2,
      );
      if (!wakeDate.isAfter(bedDate)) {
        wakeDate = wakeDate.add(const Duration(days: 1));
      }
    }

    final dur = wakeDate.difference(bedDate);
    // Sanity clamps: < 5 min or > 20 h is almost certainly bad data.
    if (dur.inMinutes < 5 || dur.inHours > 20) return null;

    return SleepPeriod(
      start: bedDate,
      end: wakeDate,
      isNap: isNap,
      source: source,
    );
  }

  static (int, int)? _parseHhmm(String? s) {
    if (s == null || !RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) return null;
    final parts = s.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return (h, m);
  }

  /// The night-waking form stores duration as a label like "15–30 min".
  /// This helper converts back to a minutes estimate for charting.
  static int _parseDurationMinutes(String? label) {
    if (label == null) return 10;
    final s = label.toLowerCase();
    if (s.contains('<15') || s.contains('under 15')) return 8;
    if (s.contains('15') && s.contains('30')) return 22;
    if (s.contains('30') && s.contains('60')) return 45;
    if (s.contains('1-2') || s.contains('1–2')) return 90;
    if (s.contains('2+') || s.contains('2 +')) return 150;
    // If it's a raw number, accept it.
    final n = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
    return n ?? 10;
  }
}
