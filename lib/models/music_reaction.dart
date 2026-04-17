// lib/models/music_reaction.dart
//
// MusicReaction — the care recipient's response to a specific song or
// musical experience.
//
// NOT a music player. This is a documentation tool: caregivers capture
// WHAT was playing and HOW the person responded. Over time the reaction
// history surfaces which songs calm and which agitate — clinical
// research cites ~67% reduction in agitation when familiar music is
// matched to the person's autobiographical peak (typically 15–25 y/o).
//
// Stored at: elderProfiles/{elderId}/musicReactions/{id}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Canonical reaction categories. Integer-valued so the analytics view
/// can rank songs by a simple weighted sum (calmed +2, engaged +1,
/// sangAlong +2, noResponse 0, agitated -2).
enum MusicReaction {
  calmed,
  engaged,
  sangAlong,
  noResponse,
  agitated,
}

extension MusicReactionX on MusicReaction {
  String get label {
    switch (this) {
      case MusicReaction.calmed:
        return 'Calmed';
      case MusicReaction.engaged:
        return 'Engaged';
      case MusicReaction.sangAlong:
        return 'Sang along';
      case MusicReaction.noResponse:
        return 'No response';
      case MusicReaction.agitated:
        return 'Agitated';
    }
  }

  /// Short verb-form prompt shown in the quick-log picker.
  String get prompt {
    switch (this) {
      case MusicReaction.calmed:
        return 'Relaxed, less agitated';
      case MusicReaction.engaged:
        return 'Attentive, tapping / smiling';
      case MusicReaction.sangAlong:
        return 'Sang, hummed, or mouthed words';
      case MusicReaction.noResponse:
        return 'Didn\'t visibly react';
      case MusicReaction.agitated:
        return 'Became tense, upset, or left';
    }
  }

  IconData get icon {
    switch (this) {
      case MusicReaction.calmed:
        return Icons.self_improvement_outlined;
      case MusicReaction.engaged:
        return Icons.sentiment_very_satisfied_outlined;
      case MusicReaction.sangAlong:
        return Icons.music_note_outlined;
      case MusicReaction.noResponse:
        return Icons.sentiment_neutral_outlined;
      case MusicReaction.agitated:
        return Icons.sentiment_very_dissatisfied_outlined;
    }
  }

  Color get color {
    switch (this) {
      case MusicReaction.calmed:
        return AppTheme.statusGreen;
      case MusicReaction.engaged:
        return AppTheme.tileTeal;
      case MusicReaction.sangAlong:
        return AppTheme.tileBlueDark;
      case MusicReaction.noResponse:
        return AppTheme.textSecondary;
      case MusicReaction.agitated:
        return AppTheme.dangerColor;
    }
  }

  /// Score contribution for the "top songs" rollup. Positive = helpful,
  /// negative = harmful, 0 = neutral.
  int get scoreWeight {
    switch (this) {
      case MusicReaction.calmed:
        return 2;
      case MusicReaction.engaged:
        return 1;
      case MusicReaction.sangAlong:
        return 2;
      case MusicReaction.noResponse:
        return 0;
      case MusicReaction.agitated:
        return -2;
    }
  }

  /// True when the reaction suggests the song is helpful. Used for
  /// "what should I play?" filtering.
  bool get isHelpful =>
      this == MusicReaction.calmed ||
      this == MusicReaction.engaged ||
      this == MusicReaction.sangAlong;

  String get firestoreValue {
    switch (this) {
      case MusicReaction.calmed:
        return 'calmed';
      case MusicReaction.engaged:
        return 'engaged';
      case MusicReaction.sangAlong:
        return 'sang_along';
      case MusicReaction.noResponse:
        return 'no_response';
      case MusicReaction.agitated:
        return 'agitated';
    }
  }

  static MusicReaction fromString(String? value) {
    switch (value) {
      case 'calmed':
        return MusicReaction.calmed;
      case 'engaged':
        return MusicReaction.engaged;
      case 'sang_along':
        return MusicReaction.sangAlong;
      case 'agitated':
        return MusicReaction.agitated;
      case 'no_response':
      default:
        return MusicReaction.noResponse;
    }
  }
}

/// Context in which the music was played. Helps tease apart whether a
/// song calms in general or only during a specific trigger (e.g.,
/// during bathing, sundowning hour).
enum MusicContext {
  general,
  sundowning,
  bathing,
  mealtime,
  transition, // moving rooms, getting in car
  bedtime,
  visit, // visitors / social event
  other,
}

extension MusicContextX on MusicContext {
  String get label {
    switch (this) {
      case MusicContext.general:
        return 'General';
      case MusicContext.sundowning:
        return 'Sundowning hour';
      case MusicContext.bathing:
        return 'Bathing / ADLs';
      case MusicContext.mealtime:
        return 'Mealtime';
      case MusicContext.transition:
        return 'Transition / travel';
      case MusicContext.bedtime:
        return 'Bedtime / sleep';
      case MusicContext.visit:
        return 'Visit / social';
      case MusicContext.other:
        return 'Other';
    }
  }

  String get firestoreValue {
    switch (this) {
      case MusicContext.general:
        return 'general';
      case MusicContext.sundowning:
        return 'sundowning';
      case MusicContext.bathing:
        return 'bathing';
      case MusicContext.mealtime:
        return 'mealtime';
      case MusicContext.transition:
        return 'transition';
      case MusicContext.bedtime:
        return 'bedtime';
      case MusicContext.visit:
        return 'visit';
      case MusicContext.other:
        return 'other';
    }
  }

  static MusicContext fromString(String? v) {
    switch (v) {
      case 'sundowning':
        return MusicContext.sundowning;
      case 'bathing':
        return MusicContext.bathing;
      case 'mealtime':
        return MusicContext.mealtime;
      case 'transition':
        return MusicContext.transition;
      case 'bedtime':
        return MusicContext.bedtime;
      case 'visit':
        return MusicContext.visit;
      case 'other':
        return MusicContext.other;
      case 'general':
      default:
        return MusicContext.general;
    }
  }
}

/// Preset decade options. The stored value is the decade-start year so
/// queries stay numeric.
class MusicDecade {
  final int startYear;
  const MusicDecade(this.startYear);

  String get label => '${startYear}s';

  static const List<MusicDecade> presets = [
    MusicDecade(1930),
    MusicDecade(1940),
    MusicDecade(1950),
    MusicDecade(1960),
    MusicDecade(1970),
    MusicDecade(1980),
    MusicDecade(1990),
    MusicDecade(2000),
    MusicDecade(2010),
    MusicDecade(2020),
  ];
}

class MusicReactionEntry {
  final String? id;
  final String elderId;

  final String song;
  final String? artist;

  /// Decade start year (1930, 1940, …). null when the caregiver
  /// doesn't know — the form accepts "unknown".
  final int? decade;

  final MusicReaction reaction;
  final MusicContext context;
  final String? notes;

  /// HH:mm local time. Drives the sundowning / bedtime correlation
  /// view without needing to dig through createdAt timezones.
  final String timeOfDay;

  final String loggedByUid;
  final String loggedByName;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const MusicReactionEntry({
    this.id,
    required this.elderId,
    required this.song,
    this.artist,
    this.decade,
    required this.reaction,
    this.context = MusicContext.general,
    this.notes,
    required this.timeOfDay,
    required this.loggedByUid,
    this.loggedByName = '',
    this.createdAt,
    this.updatedAt,
  });

  /// The canonical "identity key" of a song used for the top-songs
  /// rollup. Case-insensitive song + artist pair; a song with no
  /// artist groups under just the title.
  String get songKey {
    final s = song.trim().toLowerCase();
    final a = (artist ?? '').trim().toLowerCase();
    return a.isEmpty ? s : '$s | $a';
  }

  String get displayTitle {
    if (artist != null && artist!.trim().isNotEmpty) {
      return '$song — ${artist!.trim()}';
    }
    return song;
  }

  /// Convenience getter for analytics.
  int get scoreWeight => reaction.scoreWeight;

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toFirestore() => {
        'elderId': elderId,
        'song': song.trim(),
        if (artist != null && artist!.trim().isNotEmpty)
          'artist': artist!.trim(),
        if (decade != null) 'decade': decade,
        'reaction': reaction.firestoreValue,
        'context': context.firestoreValue,
        if (notes != null && notes!.trim().isNotEmpty)
          'notes': notes!.trim(),
        'timeOfDay': timeOfDay,
        'loggedByUid': loggedByUid,
        'loggedByName': loggedByName,
      };

  factory MusicReactionEntry.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return MusicReactionEntry(
      id: docId,
      elderId: data['elderId'] as String? ?? '',
      song: data['song'] as String? ?? '',
      artist: data['artist'] as String?,
      decade: (data['decade'] as num?)?.toInt(),
      reaction: MusicReactionX.fromString(data['reaction'] as String?),
      context: MusicContextX.fromString(data['context'] as String?),
      notes: data['notes'] as String?,
      timeOfDay: data['timeOfDay'] as String? ?? '',
      loggedByUid: data['loggedByUid'] as String? ?? '',
      loggedByName: data['loggedByName'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  MusicReactionEntry copyWith({
    String? id,
    String? elderId,
    String? song,
    String? artist,
    int? decade,
    MusicReaction? reaction,
    MusicContext? context,
    String? notes,
    String? timeOfDay,
    String? loggedByUid,
    String? loggedByName,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return MusicReactionEntry(
      id: id ?? this.id,
      elderId: elderId ?? this.elderId,
      song: song ?? this.song,
      artist: artist ?? this.artist,
      decade: decade ?? this.decade,
      reaction: reaction ?? this.reaction,
      context: context ?? this.context,
      notes: notes ?? this.notes,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      loggedByUid: loggedByUid ?? this.loggedByUid,
      loggedByName: loggedByName ?? this.loggedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Aggregated insights
//
// Derived client-side from a list of MusicReactionEntry so we don't have
// to maintain roll-up documents in Firestore. At ~50 entries per elder
// the math is trivial; if the dataset grows past ~1000 entries per
// elder this can be promoted to a server-side aggregation.
// ---------------------------------------------------------------------------

class SongInsight {
  final String song;
  final String? artist;
  final int plays;
  final int score; // sum of reaction weights
  final Map<MusicReaction, int> counts;
  final MusicReactionEntry mostRecent;

  const SongInsight({
    required this.song,
    this.artist,
    required this.plays,
    required this.score,
    required this.counts,
    required this.mostRecent,
  });

  /// The dominant reaction — whichever count is highest. Ties break
  /// toward the highest-weighted reaction so a song with 2 calmed and
  /// 2 agitated surfaces as "calmed" (hope-biased UI).
  MusicReaction get dominant {
    MusicReaction best = MusicReaction.noResponse;
    int bestCount = -1;
    int bestWeight = -100;
    counts.forEach((r, c) {
      if (c > bestCount || (c == bestCount && r.scoreWeight > bestWeight)) {
        best = r;
        bestCount = c;
        bestWeight = r.scoreWeight;
      }
    });
    return best;
  }

  String get displayTitle =>
      artist == null || artist!.isEmpty ? song : '$song — $artist';
}

class MusicInsights {
  final int totalPlays;
  final List<SongInsight> topHelpful;
  final List<SongInsight> topAgitating;

  /// decade-start year → { reaction → count }. Lets the UI shade a
  /// decade "heatmap" bar so the caregiver can see which era of music
  /// resonates most.
  final Map<int, Map<MusicReaction, int>> decadeBreakdown;

  /// Most-effective decade = the one with the highest average score.
  final int? bestDecade;

  /// Per-context score averages — lets the UI recommend different
  /// songs for sundowning vs bedtime.
  final Map<MusicContext, double> contextAverages;

  const MusicInsights({
    required this.totalPlays,
    required this.topHelpful,
    required this.topAgitating,
    required this.decadeBreakdown,
    required this.bestDecade,
    required this.contextAverages,
  });

  static MusicInsights compute(List<MusicReactionEntry> entries) {
    if (entries.isEmpty) {
      return const MusicInsights(
        totalPlays: 0,
        topHelpful: [],
        topAgitating: [],
        decadeBreakdown: {},
        bestDecade: null,
        contextAverages: {},
      );
    }

    // Group by songKey
    final Map<String, List<MusicReactionEntry>> byKey = {};
    for (final e in entries) {
      byKey.putIfAbsent(e.songKey, () => []).add(e);
    }

    final insights = <SongInsight>[];
    byKey.forEach((_, group) {
      final counts = <MusicReaction, int>{};
      int score = 0;
      for (final e in group) {
        counts[e.reaction] = (counts[e.reaction] ?? 0) + 1;
        score += e.scoreWeight;
      }
      // Most-recent entry — entries arrive newest-first so [0].
      insights.add(SongInsight(
        song: group.first.song,
        artist: group.first.artist,
        plays: group.length,
        score: score,
        counts: counts,
        mostRecent: group.first,
      ));
    });

    final helpful = insights.where((s) => s.score > 0).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return b.plays.compareTo(a.plays);
      });

    final agitating = insights.where((s) => s.score < 0).toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    // Decade rollup
    final Map<int, Map<MusicReaction, int>> decadeBreakdown = {};
    final Map<int, int> decadeScore = {};
    final Map<int, int> decadePlays = {};
    for (final e in entries) {
      final d = e.decade;
      if (d == null) continue;
      final bucket = decadeBreakdown.putIfAbsent(d, () => {});
      bucket[e.reaction] = (bucket[e.reaction] ?? 0) + 1;
      decadeScore[d] = (decadeScore[d] ?? 0) + e.scoreWeight;
      decadePlays[d] = (decadePlays[d] ?? 0) + 1;
    }

    int? bestDecade;
    double bestAvg = -double.infinity;
    decadeScore.forEach((d, s) {
      final plays = decadePlays[d] ?? 1;
      final avg = s / plays;
      if (avg > bestAvg && plays >= 2) {
        bestAvg = avg;
        bestDecade = d;
      }
    });

    // Context averages
    final Map<MusicContext, int> cScore = {};
    final Map<MusicContext, int> cPlays = {};
    for (final e in entries) {
      cScore[e.context] = (cScore[e.context] ?? 0) + e.scoreWeight;
      cPlays[e.context] = (cPlays[e.context] ?? 0) + 1;
    }
    final Map<MusicContext, double> contextAverages = {};
    cScore.forEach((c, s) {
      final p = cPlays[c] ?? 1;
      contextAverages[c] = s / p;
    });

    return MusicInsights(
      totalPlays: entries.length,
      topHelpful: helpful.take(5).toList(),
      topAgitating: agitating.take(5).toList(),
      decadeBreakdown: decadeBreakdown,
      bestDecade: bestDecade,
      contextAverages: contextAverages,
    );
  }
}
