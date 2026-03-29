// lib/models/badge.dart
//
// Badge with tiered progression: none → bronze → silver → gold → diamond.
//
// Backward compatible — `unlocked` still works (true if tier >= bronze).
// The tier system adds visual progression and milestone thresholds so
// badges feel like achievements worth pursuing, not just checkboxes.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Badge tier — determines the visual treatment (color, icon) and the
// threshold that was reached.
// ---------------------------------------------------------------------------
enum BadgeTier {
  none,     // Not yet earned
  bronze,   // Entry level — e.g. 7-day streak, first journal entry
  silver,   // Intermediate — e.g. 30-day streak, 10 journal entries
  gold,     // Advanced — e.g. 90-day streak, 50 journal entries
  diamond,  // Mastery — e.g. 365-day streak, 100+ journal entries
}

/// Visual properties for each tier.
class BadgeTierStyle {
  final Color color;
  final Color backgroundColor;
  final Color textColor;
  final String label;

  const BadgeTierStyle({
    required this.color,
    required this.backgroundColor,
    required this.textColor,
    required this.label,
  });

  static const BadgeTierStyle none = BadgeTierStyle(
    color: Color(0xFFBDBDBD),
    backgroundColor: Color(0xFFF5F5F5),
    textColor: Color(0xFFBDBDBD),
    label: 'Locked',
  );

  static const BadgeTierStyle bronze = BadgeTierStyle(
    color: Color(0xFFCD7F32),
    backgroundColor: Color(0xFFFFF3E0),
    textColor: Color(0xFF8D5524),
    label: 'Bronze',
  );

  static const BadgeTierStyle silver = BadgeTierStyle(
    color: Color(0xFFA0A0A0),
    backgroundColor: Color(0xFFF5F5F5),
    textColor: Color(0xFF616161),
    label: 'Silver',
  );

  static const BadgeTierStyle gold = BadgeTierStyle(
    color: Color(0xFFFFC107),
    backgroundColor: Color(0xFFFFF8E1),
    textColor: Color(0xFF8D6E00),
    label: 'Gold',
  );

  static const BadgeTierStyle diamond = BadgeTierStyle(
    color: Color(0xFF00BCD4),
    backgroundColor: Color(0xFFE0F7FA),
    textColor: Color(0xFF00838F),
    label: 'Diamond',
  );

  static BadgeTierStyle forTier(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.none:    return none;
      case BadgeTier.bronze:  return bronze;
      case BadgeTier.silver:  return silver;
      case BadgeTier.gold:    return gold;
      case BadgeTier.diamond: return diamond;
    }
  }
}

// ---------------------------------------------------------------------------
// Badge thresholds — defines how many of [thing] earns each tier.
// Used by BadgeProvider to check progress and upgrade tiers.
// ---------------------------------------------------------------------------
class BadgeThresholds {
  final int bronze;
  final int silver;
  final int gold;
  final int diamond;

  const BadgeThresholds({
    required this.bronze,
    required this.silver,
    required this.gold,
    required this.diamond,
  });

  /// Returns the highest tier achieved for a given count.
  BadgeTier tierForCount(int count) {
    if (count >= diamond) return BadgeTier.diamond;
    if (count >= gold) return BadgeTier.gold;
    if (count >= silver) return BadgeTier.silver;
    if (count >= bronze) return BadgeTier.bronze;
    return BadgeTier.none;
  }

  /// Returns the threshold for the next tier above [current], or null if max.
  int? nextThreshold(BadgeTier current) {
    switch (current) {
      case BadgeTier.none:    return bronze;
      case BadgeTier.bronze:  return silver;
      case BadgeTier.silver:  return gold;
      case BadgeTier.gold:    return diamond;
      case BadgeTier.diamond: return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Badge model
// ---------------------------------------------------------------------------
class Badge {
  final String id;
  final String label;
  final String imagePath;
  final String description;
  final bool unlocked;

  /// Current tier. Defaults to `none` for backward compatibility.
  final BadgeTier tier;

  /// Current progress count toward the next tier (e.g. current streak days).
  final int progressCount;

  /// Thresholds for this badge's tier progression. Null for badges that
  /// don't use the tier system (legacy badges).
  final BadgeThresholds? thresholds;

  const Badge({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.description,
    this.unlocked = false,
    this.tier = BadgeTier.none,
    this.progressCount = 0,
    this.thresholds,
  });

  /// True if the badge has been earned at any tier.
  bool get isEarned => tier != BadgeTier.none || unlocked;

  /// The style (colors, label) for the current tier.
  BadgeTierStyle get tierStyle => BadgeTierStyle.forTier(tier);

  /// Progress toward the next tier as 0.0–1.0. Returns 1.0 if at max tier.
  double get progressToNextTier {
    if (thresholds == null) return unlocked ? 1.0 : 0.0;
    final next = thresholds!.nextThreshold(tier);
    if (next == null) return 1.0; // Already at diamond.

    // Find the current tier's threshold (0 for none).
    int currentThreshold;
    switch (tier) {
      case BadgeTier.none:    currentThreshold = 0; break;
      case BadgeTier.bronze:  currentThreshold = thresholds!.bronze; break;
      case BadgeTier.silver:  currentThreshold = thresholds!.silver; break;
      case BadgeTier.gold:    currentThreshold = thresholds!.gold; break;
      case BadgeTier.diamond: currentThreshold = thresholds!.diamond; break;
    }

    final range = next - currentThreshold;
    if (range <= 0) return 1.0;
    return ((progressCount - currentThreshold) / range).clamp(0.0, 1.0);
  }

  /// Human-readable progress string, e.g. "7 / 30 days".
  String get progressLabel {
    if (thresholds == null) return unlocked ? 'Earned' : 'Not yet';
    final next = thresholds!.nextThreshold(tier);
    if (next == null) return 'Max tier reached';
    return '$progressCount / $next';
  }

  Badge copyWith({
    String? id,
    String? label,
    String? imagePath,
    String? description,
    bool? unlocked,
    BadgeTier? tier,
    int? progressCount,
    BadgeThresholds? thresholds,
  }) {
    return Badge(
      id: id ?? this.id,
      label: label ?? this.label,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      unlocked: unlocked ?? this.unlocked,
      tier: tier ?? this.tier,
      progressCount: progressCount ?? this.progressCount,
      thresholds: thresholds ?? this.thresholds,
    );
  }
}

// ---------------------------------------------------------------------------
// Badge definitions — the full catalog with tier thresholds.
//
// BadgeProvider uses these to initialize the badge map and check progress.
// Add new badges here; the provider auto-discovers them.
// ---------------------------------------------------------------------------
class BadgeCatalog {
  BadgeCatalog._();

  // Streak badges
  static const Badge streakBadge = Badge(
    id: 'streak',
    label: 'Consistent Caregiver',
    imagePath: '',
    description: 'Maintain a daily check-in streak.',
    thresholds: BadgeThresholds(bronze: 7, silver: 30, gold: 90, diamond: 365),
  );

  // Journal badges
  static const Badge journalBadge = Badge(
    id: 'journal',
    label: 'Reflective Mind',
    imagePath: '',
    description: 'Write entries in your caregiver journal.',
    thresholds: BadgeThresholds(bronze: 1, silver: 10, gold: 50, diamond: 100),
  );

  // Breathing exercise badges
  static const Badge breathingBadge = Badge(
    id: 'breathing',
    label: 'Zen Master',
    imagePath: '',
    description: 'Complete breathing exercises.',
    thresholds: BadgeThresholds(bronze: 3, silver: 25, gold: 100, diamond: 500),
  );

  // Care log badges
  static const Badge careLogBadge = Badge(
    id: 'care_log',
    label: 'Devoted Caregiver',
    imagePath: '',
    description: 'Log care activities for your care recipient.',
    thresholds: BadgeThresholds(bronze: 10, silver: 50, gold: 200, diamond: 1000),
  );

  // Challenge completion badges
  static const Badge challengeBadge = Badge(
    id: 'challenges',
    label: 'Challenge Accepted',
    imagePath: '',
    description: 'Complete weekly challenges.',
    thresholds: BadgeThresholds(bronze: 1, silver: 5, gold: 15, diamond: 52),
  );

  // Points milestone badges
  static const Badge pointsBadge = Badge(
    id: 'points',
    label: 'Point Collector',
    imagePath: '',
    description: 'Earn lifetime points through self-care and caregiving.',
    thresholds: BadgeThresholds(bronze: 100, silver: 1000, gold: 5000, diamond: 25000),
  );

  // Mood tracking badges
  static const Badge moodBadge = Badge(
    id: 'mood_tracker',
    label: 'Mood Monitor',
    imagePath: '',
    description: 'Track your mood consistently.',
    thresholds: BadgeThresholds(bronze: 7, silver: 30, gold: 90, diamond: 365),
  );

  // Self-care variety badge (used different relief tools)
  static const Badge selfCareBadge = Badge(
    id: 'self_care',
    label: 'Self-Care Champion',
    imagePath: '',
    description: 'Use a variety of self-care tools regularly.',
    thresholds: BadgeThresholds(bronze: 5, silver: 20, gold: 75, diamond: 200),
  );

  /// All badge templates in the catalog.
  static const List<Badge> all = [
    streakBadge,
    journalBadge,
    breathingBadge,
    careLogBadge,
    challengeBadge,
    pointsBadge,
    moodBadge,
    selfCareBadge,
  ];

  /// Lookup by id.
  static Badge? byId(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
